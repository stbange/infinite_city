extends GutTest
## Spec city-lighting: Neon signs, Sign placement, Bridge lamps.

const EPS := 0.01

var city: CityLayout
var pockets: PocketLayout
var lighting: CityLighting


func before_each() -> void:
	city = CityLayout.new(CityConfig.new())
	pockets = PocketLayout.new(city)
	lighting = CityLighting.new(city)


func _blocks(count: int, salt: int) -> Array[BlockInfo]:
	var blocks: Array[BlockInfo] = []
	var rng := CellRandom.new(salt)
	while blocks.size() < count:
		var block := city.block_at(Vector3i(rng.range_int(-300, 300), rng.range_int(-200, 0), rng.range_int(-300, 300)))
		if block != null:
			blocks.append(block)
	return blocks


func _signs(block: BlockInfo) -> Array[SignInfo]:
	return lighting.signs_of(block, pockets.doorway_for_block(block))


func test_signs_per_function() -> void:
	var markets := 0
	var busy_markets := 0
	var services := 0
	var single_services := 0
	for block in _blocks(3000, 1):
		var count := _signs(block).size()
		match block.kind:
			BlockTypes.Kind.MARKET:
				markets += 1
				assert_lte(count, 3)
				if count >= 2:
					busy_markets += 1
			BlockTypes.Kind.OFFICE:
				assert_lte(count, 2)
			_:
				assert_lte(count, 1)
				if BlockTypes.is_service(block.kind):
					services += 1
					if count == 1:
						single_services += 1
	assert_gt(markets, 50)
	assert_gte(float(busy_markets) / markets, 0.7)
	# Services are rare in a random sample; check the ones of whole districts as well.
	for dx in 4:
		for dz in 4:
			var plan := city.district_plan(Vector3i(dx, -2, dz))
			for cell: Vector3i in plan:
				services += 1
				if _signs(city.block_at(cell)).size() == 1:
					single_services += 1
	assert_gte(float(single_services) / services, 0.9)


func test_service_signs_show_the_service_colour() -> void:
	var seen := 0
	for dx in 4:
		for dz in 4:
			var plan := city.district_plan(Vector3i(dx, -3, dz))
			for cell: Vector3i in plan:
				var block := city.block_at(cell)
				for sign in _signs(block):
					seen += 1
					assert_eq(sign.color, BlockTypes.color(block.kind))
	assert_gt(seen, 50)


func test_some_signs_flicker() -> void:
	var signs := 0
	var flickering := 0
	for block in _blocks(4000, 2):
		for sign in _signs(block):
			signs += 1
			if sign.flicker:
				flickering += 1
		if signs >= 2000:
			break
	assert_gte(signs, 2000)
	assert_between(float(flickering) / signs, 0.08, 0.22)


func test_same_signs_every_time() -> void:
	var other := CityLighting.new(CityLayout.new(CityConfig.new()))
	for block in _blocks(300, 3):
		var a := _signs(block)
		var b := other.signs_of(block, pockets.doorway_for_block(block))
		assert_eq(a.size(), b.size())
		for i in a.size():
			assert_true(a[i].equals(b[i]))


func test_signs_stay_clear() -> void:
	var total := 0
	for block in _blocks(1000, 4):
		var doorway := pockets.doorway_for_block(block)
		var signs := _signs(block)
		for i in signs.size():
			var sign := signs[i]
			total += 1
			var axis := sign.face_axis
			var lat := CityLighting.lateral_axis(axis)
			var face := block.max_local()[axis] if sign.face_sign > 0 else block.min_local()[axis]
			assert_almost_eq(sign.centre[axis], face + sign.face_sign * 0.3, EPS)
			var lo := sign.centre[lat] - sign.size.x * 0.5
			var hi := sign.centre[lat] + sign.size.x * 0.5
			var bottom := sign.centre.y - sign.size.y * 0.5
			var top := sign.centre.y + sign.size.y * 0.5
			assert_true(lo >= block.min_local()[lat] + 1.0 - EPS and hi <= block.max_local()[lat] - 1.0 + EPS, "sign leaves its face sideways")
			assert_true(bottom >= block.min_local().y + 1.0 - EPS and top <= block.max_local().y - 1.0 + EPS, "sign leaves its face vertically")
			assert_true(hi <= -8.0 + EPS or lo >= 8.0 - EPS, "sign reaches into the bridge band")
			if doorway != null and doorway.face_axis == axis and doorway.face_sign == sign.face_sign:
				var d_lat := doorway.door.origin[lat]
				var d_y := doorway.door.origin.y
				var overlaps_door := hi > d_lat - 3.0 and lo < d_lat + 3.0 and top > d_y - 1.0 and bottom < d_y + 7.0
				assert_false(overlaps_door, "sign overlaps the magic doorway")
			for j in range(i + 1, signs.size()):
				var other := signs[j]
				if other.face_axis != axis or other.face_sign != sign.face_sign:
					continue
				var o_lo := other.centre[lat] - other.size.x * 0.5
				var o_hi := other.centre[lat] + other.size.x * 0.5
				var o_bottom := other.centre.y - other.size.y * 0.5
				var o_top := other.centre.y + other.size.y * 0.5
				assert_false(hi > o_lo and lo < o_hi and top > o_bottom and bottom < o_top, "signs overlap")
	assert_gt(total, 300)


func test_lamps_along_a_bridge() -> void:
	var bridges := 0
	var rng := CellRandom.new(5)
	while bridges < 300:
		var cell := Vector3i(rng.range_int(-300, 300), rng.range_int(-200, 0), rng.range_int(-300, 300))
		for axis in CityLayout.BRIDGE_AXES:
			var bridge := city.bridge_between(cell, axis)
			if bridge == null:
				continue
			bridges += 1
			var lamps := lighting.lamps_of(bridge)
			var per_edge := maxi(1, floori((bridge.length() - 4.0) / 12.0) + 1)
			assert_eq(lamps.size(), per_edge * 2)
			var lat := CityLighting.lateral_axis(axis)
			var left := 0
			for lamp in lamps:
				assert_almost_eq(lamp.position.y, bridge.start.y + 3.2, EPS)
				assert_almost_eq(absf(lamp.position[lat] - bridge.start[lat]), bridge.width * 0.5 - 0.3, EPS)
				assert_between(lamp.position[axis], bridge.start[axis], bridge.end[axis])
				if lamp.position[lat] < bridge.start[lat]:
					left += 1
			assert_eq(left, per_edge)
