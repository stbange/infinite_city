extends GutTest
## Spec floating-origin.

var origin: FloatingOrigin


func before_each() -> void:
	origin = FloatingOrigin.for_config(CityConfig.new())


func test_defaults() -> void:
	assert_eq(origin.chunk_size(), Vector3(256, 256, 256))
	assert_eq(origin.threshold, 512.0)
	assert_eq(origin.origin_chunk, Vector3i.ZERO)


func test_absolute_cell_of_a_scene_position() -> void:
	origin.origin_chunk = Vector3i(2, -3, 1)
	assert_eq(origin.absolute_cell_of(Vector3(10, 20, 30)), Vector3i(8, -12, 4))
	assert_eq(origin.offset_in_cell(Vector3(10, 20, 30)), Vector3(10, 20, 30))


func test_absolute_cell_of_negative_scene_position() -> void:
	origin.origin_chunk = Vector3i(2, -3, 1)
	assert_eq(origin.absolute_cell_of(Vector3(-1, -65, 70)), Vector3i(7, -14, 5))
	assert_eq(origin.offset_in_cell(Vector3(-1, -65, 70)), Vector3(63, 63, 6))


func test_scene_position_of_a_far_cell() -> void:
	origin.origin_chunk = Vector3i(0, -2500000, 0)
	assert_eq(origin.scene_position_of_cell_center(Vector3i(1, -10000000, 2)), Vector3(96, 32, 160))


func test_scene_position_of_chunk() -> void:
	origin.origin_chunk = Vector3i(100000, -2500000, -7)
	assert_eq(origin.scene_position_of_chunk(Vector3i(100001, -2500002, -7)), Vector3(256, -512, 0))


func test_camera_far_from_origin() -> void:
	var camera := Vector3(600, 0, 0)
	var delta := origin.rebase_delta(camera)
	assert_eq(delta, Vector3i(2, 0, 0))
	var shift := origin.apply_rebase(delta)
	assert_eq(shift, Vector3(512, 0, 0))
	assert_eq(camera - shift, Vector3(88, 0, 0))
	assert_eq(origin.origin_chunk, Vector3i(2, 0, 0))


func test_camera_far_on_negative_side() -> void:
	var delta := origin.rebase_delta(Vector3(10, -700, 0))
	assert_eq(delta, Vector3i(0, -3, 0))


func test_camera_near_origin() -> void:
	assert_eq(origin.rebase_delta(Vector3(-10, -500, 300)), Vector3i.ZERO)


func test_markers_keep_their_place() -> void:
	origin.origin_chunk = Vector3i(5, -40, 9)
	var markers: Array[Vector3] = [Vector3(0, 0, 0), Vector3(511.5, -3.25, 100), Vector3(-700, 20, -40)]
	var before: Array[PackedFloat64Array] = []
	for marker in markers:
		before.append(origin.absolute_metres(marker))
	var shift := origin.apply_rebase(Vector3i(3, -1, 2))
	for i in markers.size():
		var after := origin.absolute_metres(markers[i] - shift)
		for axis in 3:
			assert_almost_eq(after[axis], before[i][axis], 0.001)


func test_long_flight() -> void:
	var camera := Vector3(0, 10, 0)
	var start := origin.absolute_metres(camera)
	var max_offset := 0.0
	for step in 10000:
		camera.x += 10.0
		var delta := origin.rebase_delta(camera)
		if delta != Vector3i.ZERO:
			camera -= origin.apply_rebase(delta)
		max_offset = maxf(max_offset, maxf(absf(camera.x), maxf(absf(camera.y), absf(camera.z))))
	assert_lte(max_offset, 522.0)
	var end := origin.absolute_metres(camera)
	assert_almost_eq(end[0] - start[0], 100000.0, 0.01)
	assert_almost_eq(end[1], start[1], 0.01)


func test_place_origin_at_absolute_position() -> void:
	var absolute := PackedFloat64Array([1000000.5, -640000000.25, -3.0])
	var scene := origin.place_origin_at(absolute)
	assert_lt(scene.length(), 256.0 * 1.8)
	var back := origin.absolute_metres(scene)
	for axis in 3:
		assert_almost_eq(back[axis], absolute[axis], 0.001)
