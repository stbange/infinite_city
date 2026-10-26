extends GutTest
## Spec world-streaming.

var planner: StreamingPlanner


func before_each() -> void:
	planner = StreamingPlanner.for_config(CityConfig.new())


func _as_set(chunks: Array[Vector3i]) -> Dictionary:
	var result := {}
	for chunk in chunks:
		result[chunk] = true
	return result


func test_default_radii_and_top() -> void:
	assert_eq(planner.radius_h, 4)
	assert_eq(planner.radius_v, 3)
	assert_eq(planner.top_chunk_y, 1)
	assert_eq(planner.budget, 4)


func test_chunks_inside_and_outside_the_region() -> void:
	var focus := Vector3i(0, -2, 0)
	var region := _as_set(planner.load_order(focus))
	for inside: Vector3i in [Vector3i(0, -2, 0), Vector3i(4, -2, 0), Vector3i(-4, -2, 0), Vector3i(0, -5, 0)]:
		assert_true(region.has(inside), "%s should be in the region" % inside)
	for outside: Vector3i in [Vector3i(5, -2, 0), Vector3i(0, -6, 0), Vector3i(3, -4, 3)]:
		assert_false(region.has(outside), "%s should not be in the region" % outside)


func test_focus_above_the_city() -> void:
	var order := planner.load_order(Vector3i(0, 3, 0))
	for chunk in order:
		assert_lte(chunk.y, 1)


func test_focus_far_above_the_city_loads_nothing() -> void:
	assert_eq(planner.load_order(Vector3i(0, 100, 0)).size(), 0)


func test_load_order_is_nearest_first() -> void:
	var focus := Vector3i(2, -1, -3)
	var order := planner.load_order(focus)
	assert_eq(order[0], focus)
	var previous := -1.0
	for chunk in order:
		var distance := planner.region_distance(chunk - focus)
		assert_gte(distance, previous)
		previous = distance


func test_load_order_has_no_duplicates() -> void:
	var order := planner.load_order(Vector3i(0, -10, 0))
	assert_eq(_as_set(order).size(), order.size())


func test_first_update_loads_the_four_nearest_chunks() -> void:
	var focus := Vector3i(0, -2, 0)
	var loads := planner.next_loads(focus, {})
	assert_eq(loads.size(), 4)
	assert_eq(loads, planner.load_order(focus).slice(0, 4))


func test_region_fills_up_over_updates() -> void:
	var focus := Vector3i(7, -9, -2)
	var loaded := {}
	var updates := 0
	while true:
		var loads := planner.next_loads(focus, loaded)
		if loads.is_empty():
			break
		assert_lte(loads.size(), 4)
		for chunk in loads:
			loaded[chunk] = true
		updates += 1
		assert_lt(updates, 1000, "streaming never completes")
	assert_eq(loaded, _as_set(planner.load_order(focus)))
	assert_eq(planner.next_loads(focus, loaded).size(), 0)


func test_small_moves_keep_chunks() -> void:
	var loaded := _as_set(planner.load_order(Vector3i(0, -2, 0)))
	var unload := planner.to_unload(Vector3i(1, -2, 0), loaded)
	assert_false(unload.has(Vector3i(-4, -2, 0)))


func test_large_moves_release_chunks() -> void:
	var loaded := _as_set(planner.load_order(Vector3i(0, -2, 0)))
	var unload := planner.to_unload(Vector3i(2, -2, 0), loaded)
	assert_true(unload.has(Vector3i(-4, -2, 0)))
	for chunk in unload:
		assert_gt(planner.region_distance(chunk - Vector3i(2, -2, 0), 5, 4), 1.0)


func test_custom_radii() -> void:
	var small := StreamingPlanner.new(1, 1, 10)
	assert_eq(small.load_order(Vector3i.ZERO).size(), 7)
