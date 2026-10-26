extends GutTest
## Spec block-interiors: Floors, Corridors reach every face, Units open onto corridors,
## Entrances, Deterministic interiors (plans).

const EPS := 0.01

var city: CityLayout
var interiors: InteriorLayout


func before_each() -> void:
	city = CityLayout.new(CityConfig.new())
	interiors = InteriorLayout.new(city, PocketLayout.new(city))


func _blocks(count: int, salt: int) -> Array[BlockInfo]:
	var blocks: Array[BlockInfo] = []
	var rng := CellRandom.new(salt)
	while blocks.size() < count:
		var block := city.block_at(Vector3i(rng.range_int(-300, 300), rng.range_int(-150, 0), rng.range_int(-300, 300)))
		if block != null:
			blocks.append(block)
	return blocks


func test_floor_levels() -> void:
	for block in _blocks(200, 1):
		var plan := interiors.plan_of(block)
		assert_eq(plan.floors, roundi(block.size.y / 4.0))
		assert_almost_eq(plan.bottom, block.min_local().y, EPS)
		for k in plan.floors:
			assert_almost_eq(plan.floor_y(k), block.min_local().y + 4.0 * k, EPS)


func test_corridor_cross() -> void:
	for block in _blocks(200, 2):
		var plan := interiors.plan_of(block)
		var along_z := false
		var along_x := false
		for corridor in plan.corridors:
			if absf(corridor.get_center().x) < EPS and absf(corridor.size.x - 2.5) < EPS \
					and corridor.position.y <= plan.inner.position.y + EPS and corridor.end.y >= plan.inner.end.y - EPS:
				along_z = true
			if absf(corridor.get_center().y) < EPS and absf(corridor.size.y - 2.5) < EPS \
					and corridor.position.x <= plan.inner.position.x + EPS and corridor.end.x >= plan.inner.end.x - EPS:
				along_x = true
		assert_true(along_z and along_x, "corridor cross missing in %s" % block.cell)


func _on_corridor_edge(plan: InteriorPlan, point: Vector2) -> bool:
	for corridor in plan.corridors:
		var on_z_edge := absf(point.y - corridor.position.y) < EPS or absf(point.y - corridor.end.y) < EPS
		if on_z_edge and point.x >= corridor.position.x - EPS and point.x <= corridor.end.x + EPS:
			return true
	return false


func test_units_and_doors() -> void:
	for block in _blocks(200, 3):
		var plan := interiors.plan_of(block)
		var inner := plan.inner.grow(EPS)
		assert_gt(plan.units.size(), 1)
		var cores := 0
		for i in plan.units.size():
			var unit := plan.units[i]
			var shrunk := unit.rect.grow(-EPS)
			assert_true(inner.encloses(unit.rect), "unit %d of %s outside the walls" % [i, block.cell])
			for corridor in plan.corridors:
				assert_false(shrunk.intersects(corridor), "unit %d of %s overlaps a corridor" % [i, block.cell])
			if unit.is_core:
				cores += 1
				assert_true(unit.rect.grow(EPS).encloses(plan.core))
			else:
				assert_false(shrunk.intersects(plan.core), "unit %d of %s overlaps the stair core" % [i, block.cell])
			for j in range(i + 1, plan.units.size()):
				assert_false(shrunk.intersects(plan.units[j].rect.grow(-EPS)), "units overlap in %s" % block.cell)
			var door := Vector2(unit.door_x, unit.front_z())
			assert_true(door.x >= unit.rect.position.x + 0.5 - EPS and door.x <= unit.rect.end.x - 0.5 + EPS)
			assert_true(_on_corridor_edge(plan, door), "door of unit %d in %s is not on a corridor" % [i, block.cell])
		assert_eq(cores, 1)


func test_entrances_at_bridges() -> void:
	var pockets := PocketLayout.new(city)
	var checked := 0
	for block in _blocks(1200, 4):
		var bridges := city.bridges_of(block.cell)
		if bridges.is_empty():
			continue
		checked += 1
		var plan := interiors.plan_of(block)
		var doorway := pockets.doorway_for_block(block)
		var expected := 0
		for bridge in bridges:
			var sign := 1 if bridge.cell_a == block.cell else -1
			var floor := roundi((bridge.start.y - plan.bottom) / 4.0)
			var magic := doorway != null and doorway.on_bridge and doorway.face_axis == bridge.axis and doorway.face_sign == sign
			if magic:
				assert_false(plan.has_entrance(floor, bridge.axis, sign))
			else:
				expected += 1
				assert_true(plan.has_entrance(floor, bridge.axis, sign), "missing entrance in %s" % block.cell)
		assert_eq(plan.entrances.size(), expected, "entrances without a bridge in %s" % block.cell)
		if checked >= 300:
			break
	assert_eq(checked, 300)


func test_same_plan_every_time() -> void:
	var other := InteriorLayout.new(CityLayout.new(CityConfig.new()), PocketLayout.new(city))
	for block in _blocks(30, 5):
		var a := interiors.plan_of(block)
		var b := other.plan_of(block)
		assert_eq(a.corridors, b.corridors)
		assert_eq(a.core, b.core)
		assert_eq(a.units.size(), b.units.size())
		for i in a.units.size():
			assert_eq(a.units[i].rect, b.units[i].rect)
			assert_eq(a.units[i].door_x, b.units[i].door_x)
