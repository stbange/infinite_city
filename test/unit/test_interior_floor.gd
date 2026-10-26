extends GutTest
## Spec block-interiors: Stairs, Windows, Flats, Themed units, Tidy furniture, Room light,
## Deterministic interiors (floors).

const EPS := 0.01

var city: CityLayout
var interiors: InteriorLayout


func before_each() -> void:
	city = CityLayout.new(CityConfig.new())
	interiors = InteriorLayout.new(city, PocketLayout.new(city))


func _blocks(count: int, salt: int, kind: int = -1) -> Array[BlockInfo]:
	var blocks: Array[BlockInfo] = []
	var rng := CellRandom.new(salt)
	var tries := 0
	while blocks.size() < count and tries < 200000:
		tries += 1
		var block := city.block_at(Vector3i(rng.range_int(-400, 400), rng.range_int(-200, 0), rng.range_int(-400, 400)))
		if block != null and (kind < 0 or block.kind == kind):
			blocks.append(block)
	return blocks


func _service_blocks(kind: int, count: int) -> Array[BlockInfo]:
	var blocks: Array[BlockInfo] = []
	for dx in range(0, 12):
		for dz in range(0, 12):
			var plan := city.district_plan(Vector3i(dx, -3, dz))
			for cell: Vector3i in plan:
				if plan[cell] == kind:
					blocks.append(city.block_at(cell))
					if blocks.size() >= count:
						return blocks
	return blocks


func test_flights_per_floor() -> void:
	for block in _blocks(50, 1):
		var plan := interiors.plan_of(block)
		for k in plan.floors:
			var floor := interiors.floor_of(plan, k)
			assert_eq(floor.flights.size(), 2)
			var y := plan.floor_y(k)
			assert_almost_eq(floor.flights[0].start.y, y, EPS)
			assert_almost_eq(floor.flights[0].end.y, y + 2.0, EPS)
			assert_almost_eq(floor.flights[1].start.y, y + 2.0, EPS)
			assert_almost_eq(floor.flights[1].end.y, y + 4.0, EPS)
			for flight in floor.flights:
				assert_almost_eq(Vector2(flight.start.x, flight.start.z).distance_to(Vector2(flight.end.x, flight.end.z)), 3.0, EPS)
				assert_almost_eq(flight.width, 1.6, EPS)
			if k + 1 < plan.floors:
				var above := interiors.floor_of(plan, k + 1)
				for flight in floor.flights:
					var mid := flight.start.lerp(flight.end, 0.5)
					var probe := Vector3(mid.x, plan.floor_y(k + 1) - 0.1, mid.z)
					for slab in above.slabs:
						assert_false(slab.has_point(probe), "no opening above the flights of floor %d in %s" % [k, block.cell])


func test_roof_access() -> void:
	for block in _blocks(20, 2):
		var plan := interiors.plan_of(block)
		var top := interiors.floor_of(plan, plan.floors - 1)
		assert_almost_eq(top.flights[1].end.y, plan.top(), EPS)
		assert_gt(top.hut.size(), 3)
		var arrival := top.flights[1].end + Vector3(0, 1.0, 0)
		var doorway := Vector3(arrival.x, plan.top() + 1.0, plan.core.position.y)
		for box in top.hut:
			assert_false(box.has_point(doorway), "the roof hut of %s has no door" % block.cell)
			assert_true(box.position.y >= plan.top() - EPS)


func test_window_grid() -> void:
	var windows := 0
	for block in _blocks(25, 3):
		var plan := interiors.plan_of(block)
		for k: int in [0, plan.floors - 1]:
			var floor := interiors.floor_of(plan, k)
			for pane in floor.glass:
				windows += 1
				var x_face := pane.size.x < pane.size.z
				var lateral := pane.get_center().z if x_face else pane.get_center().x
				var width := pane.size.z if x_face else pane.size.x
				assert_almost_eq(width, 1.6, EPS)
				assert_almost_eq(pane.size.y, 1.68, EPS)
				assert_almost_eq(pane.position.y, plan.floor_y(k) + 1.2, EPS)
				assert_almost_eq(posmod(lateral, 4.0), 2.0, EPS, "window not centred in a bay")
				var lo := block.min_local()
				var hi := block.max_local()
				assert_true(AABB(lo, hi - lo).grow(EPS).encloses(pane), "window outside the face")
	assert_gt(windows, 100)


func _names(floor: InteriorFloor, unit_index: int) -> Dictionary:
	var names := {}
	for i in floor.items.size():
		if floor.rooms[floor.item_rooms[i]].unit_index == unit_index:
			names[floor.item_names[i]] = true
	return names


func test_furnished_flats() -> void:
	var flats := 0
	for block in _blocks(40, 4, BlockTypes.Kind.HOUSING):
		var plan := interiors.plan_of(block)
		var floor := interiors.floor_of(plan, 1)
		for unit in plan.units:
			if unit.is_core:
				continue
			flats += 1
			var names := _names(floor, unit.index)
			for required: String in ["bed", "table", "counter", "shower", "toilet", "sink"]:
				assert_true(names.has(required), "flat %d of %s has no %s" % [unit.index, block.cell, required])
			assert_true(names.has("sofa") or names.has("chair"), "flat %d of %s has no seat" % [unit.index, block.cell])
		if flats >= 200:
			break
	assert_gte(flats, 200)


func test_signature_items() -> void:
	var signatures := {
		BlockTypes.Kind.OFFICE: "desk", BlockTypes.Kind.MARKET: "shelf", BlockTypes.Kind.FARM: "grow_rack",
		BlockTypes.Kind.INDUSTRY: "machine", BlockTypes.Kind.PARK: "planter",
		BlockTypes.Kind.HOSPITAL: "bed", BlockTypes.Kind.SCHOOL: "board",
	}
	for kind: int in signatures:
		var blocks := _service_blocks(kind, 10) if BlockTypes.is_service(kind) else _blocks(10, 50 + kind, kind)
		var units := 0
		for block in blocks:
			var plan := interiors.plan_of(block)
			var floor := interiors.floor_of(plan, 2)
			for unit in plan.units:
				if unit.is_core:
					continue
				units += 1
				assert_true(_names(floor, unit.index).has(signatures[kind]),
						"%s unit %d of %s has no %s" % [BlockTypes.display_name(kind), unit.index, block.cell, signatures[kind]])
				if units >= 30:
					break
			if units >= 30:
				break
		assert_gte(units, 30, "not enough %s units" % BlockTypes.display_name(kind))


func test_nothing_in_the_way() -> void:
	var floors := 0
	for block in _blocks(50, 5):
		var plan := interiors.plan_of(block)
		for k: int in [0, plan.floors / 2]:
			var floor := interiors.floor_of(plan, k)
			floors += 1
			var y := plan.floor_y(k)
			for i in floor.items.size():
				var item := floor.items[i]
				var room := floor.rooms[floor.item_rooms[i]]
				var item_rect := Rect2(item.position.x, item.position.z, item.size.x, item.size.z)
				assert_true(room.rect.grow(EPS).encloses(item_rect), "%s outside its room in %s" % [floor.item_names[i], block.cell])
				assert_true(item.position.y >= y - EPS and item.end.y <= y + 3.7 + EPS)
				var shrunk := item.grow(-0.005)
				for j in range(i + 1, floor.items.size()):
					assert_false(shrunk.intersects(floor.items[j]), "%s overlaps %s in %s" % [floor.item_names[i], floor.item_names[j], block.cell])
				for clear in floor.clear_areas:
					assert_false(shrunk.intersects(clear), "%s blocks a door in %s" % [floor.item_names[i], block.cell])
				for wall in floor.walls:
					assert_false(shrunk.intersects(wall), "%s stands in a wall in %s" % [floor.item_names[i], block.cell])
	assert_eq(floors, 100)


func test_lit_rooms() -> void:
	for block in _blocks(25, 6):
		var plan := interiors.plan_of(block)
		for k: int in [1, plan.floors - 2]:
			var floor := interiors.floor_of(plan, k)
			assert_gt(floor.rooms.size(), 0)
			for room in floor.rooms:
				assert_true(room.rect.has_point(Vector2(room.light.x, room.light.z)), "light outside room %s" % room.name)
				assert_lt(room.light.y, plan.floor_y(k) + 3.7)
				assert_gt(room.light.y, plan.floor_y(k))


func test_same_floor_every_time() -> void:
	var other := InteriorLayout.new(CityLayout.new(CityConfig.new()), PocketLayout.new(city))
	for block in _blocks(10, 7):
		var a := interiors.floor_of(interiors.plan_of(block), 3)
		var b := other.floor_of(other.plan_of(block), 3)
		assert_eq(a.items, b.items)
		assert_eq(a.item_names, b.item_names)
		assert_eq(a.walls, b.walls)
		assert_eq(a.glass, b.glass)
