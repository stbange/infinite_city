extends GutTest
## Spec city-layout: Major traffic lanes.

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func test_lane_frequency() -> void:
	for axis in 3:
		var lanes := 0
		for b in range(-300, 300):
			if layout.is_lane(axis, b):
				lanes += 1
		assert_between(lanes / 600.0, 0.10, 0.25, "share of lanes on axis %d" % axis)


func test_a_lane_runs_without_end() -> void:
	var lane := 0
	while not layout.is_lane(Vector3.AXIS_X, lane):
		lane += 1
	var plane_x := lane * layout.config.cell_size.x
	var rng := CellRandom.new(21)
	var checked := 0
	var tries := 0
	while checked < 2000 and tries < 100000:
		tries += 1
		var x := lane if rng.next_int(2) == 0 else lane - 1
		var cell := Vector3i(x, rng.range_int(-100000, 0), rng.range_int(-100000, 100000))
		var block := layout.block_at(cell)
		if block == null:
			continue
		var aabb := layout.block_aabb(block)
		var distance := minf(absf(aabb.position.x - plane_x), absf(aabb.end.x - plane_x))
		assert_gte(distance, 16.0 - 1e-3, "block %s is %s m from the lane" % [cell, distance])
		checked += 1
	assert_eq(checked, 2000)


func test_same_lanes_for_every_generator() -> void:
	var other := CityLayout.new(CityConfig.new())
	var config := CityConfig.new()
	config.world_seed = 4242
	var reseeded := CityLayout.new(config)
	var differs := false
	for axis in 3:
		for b in range(-1000, 1000):
			assert_eq(layout.is_lane(axis, b), other.is_lane(axis, b))
			if layout.is_lane(axis, b) != reseeded.is_lane(axis, b):
				differs = true
	assert_true(differs)
