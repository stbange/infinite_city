extends GutTest
## Specs world-streaming and floating-origin, exercised through the CityWorld node.

var world: CityWorld
var camera: Node3D


func before_each() -> void:
	world = CityWorld.new()
	world.config = CityConfig.new()
	world.radius_h = 2
	world.radius_v = 1
	world.chunks_per_tick = 4
	world.auto_tick = false
	camera = Node3D.new()
	camera.name = "Camera"
	world.add_child(camera)
	camera.add_to_group(CityWorld.ANCHORED_GROUP)
	world.focus_path = NodePath("Camera")
	add_child_autofree(world)
	camera.position = Vector3(128, -100, 128)  # chunk (0, -1, 0)


func _fill() -> int:
	var ticks := 0
	while not world.is_streaming_complete():
		world.tick()
		ticks += 1
		assert_lt(ticks, 500, "streaming never completes")
		if ticks >= 500:
			break
	return ticks


func _loaded_set() -> Dictionary:
	var result := {}
	for chunk in world.loaded_chunks():
		result[chunk] = true
	return result


func test_first_tick_loads_the_budget() -> void:
	world.tick()
	assert_eq(world.loaded_chunks().size(), 4)


func test_region_fills_up() -> void:
	_fill()
	var expected := {}
	for chunk in world.planner.load_order(Vector3i(0, -1, 0)):
		expected[chunk] = true
	assert_eq(_loaded_set(), expected)
	var before := world.loaded_chunks().size()
	world.tick()
	assert_eq(world.loaded_chunks().size(), before)


func test_chunk_views_show_generated_content() -> void:
	_fill()
	var views := 0
	for chunk in world.loaded_chunks():
		var data := world.layout.generate_chunk(chunk)
		var view := world.chunk_view(chunk)
		if data.is_empty():
			assert_null(view, "empty chunk %s should have no node" % chunk)
			continue
		views += 1
		assert_not_null(view)
		assert_eq(view.block_count(), data.blocks.size())
		assert_eq(view.bridge_count(), data.bridges.size())
		assert_eq(view.position, world.origin.scene_position_of_chunk(chunk))
	assert_gt(views, 0)


func test_rebase_keeps_the_world_in_place() -> void:
	_fill()
	var marker := Node3D.new()
	world.add_child(marker)
	marker.add_to_group(CityWorld.ANCHORED_GROUP)
	marker.position = Vector3(-300, 40, 75.5)
	var marker_before := world.origin.absolute_metres(marker.position)
	var camera_before := world.origin.absolute_metres(camera.position + Vector3(600, 0, 0))
	watch_signals(world)
	camera.position += Vector3(600, 0, 0)
	world.tick()
	assert_signal_emitted(world, "origin_shifted")
	assert_ne(world.origin.origin_chunk, Vector3i.ZERO)
	assert_lte(absf(camera.position.x), 512.0)
	var marker_after := world.origin.absolute_metres(marker.position)
	var camera_after := world.origin.absolute_metres(camera.position)
	for axis in 3:
		assert_almost_eq(marker_after[axis], marker_before[axis], 0.001)
		assert_almost_eq(camera_after[axis], camera_before[axis], 0.001)
	for chunk in world.loaded_chunks():
		var view := world.chunk_view(chunk)
		if view != null:
			assert_eq(view.position, world.origin.scene_position_of_chunk(chunk))


func test_moving_away_unloads_chunks() -> void:
	_fill()
	assert_true(_loaded_set().has(Vector3i(-2, -1, 0)))
	camera.position += Vector3(4 * 256, 0, 0)  # focus moves 4 chunks along +X
	world.tick()
	assert_false(_loaded_set().has(Vector3i(-2, -1, 0)))


func test_unloaded_views_are_freed() -> void:
	_fill()
	var view: ChunkView = null
	for chunk in world.loaded_chunks():
		if chunk.x == -2 and world.chunk_view(chunk) != null:
			view = world.chunk_view(chunk)
			break
	assert_not_null(view)
	camera.position += Vector3(4 * 256, 0, 0)
	world.tick()
	await wait_physics_frames(2)
	assert_false(is_instance_valid(view))


func test_nothing_loaded_above_the_city() -> void:
	camera.position = Vector3(128, 3 * 256 + 100, 128)  # chunk (0, 3, 0): region is all sky
	_fill()
	assert_eq(world.loaded_chunks().size(), 0)
	camera.position = Vector3(128, 2 * 256 + 100, 128)  # chunk (0, 2, 0): region touches the city
	_fill()
	assert_gt(world.loaded_chunks().size(), 0)
	for chunk in world.loaded_chunks():
		assert_lte(chunk.y, 1)


func test_teleport_to_absolute_position() -> void:
	_fill()
	var target := PackedFloat64Array([1000000.0, -6400000.0, 32.0])
	world.teleport_focus(target)
	var after := world.origin.absolute_metres(camera.position)
	for axis in 3:
		assert_almost_eq(after[axis], target[axis], 0.001)
	_fill()
	var focus_chunk := world.origin.absolute_chunk_of(camera.position)
	assert_true(_loaded_set().has(focus_chunk))
	for chunk in world.loaded_chunks():
		assert_lte(world.planner.region_distance(chunk - focus_chunk), 1.0)


func _place_entrance_marker() -> Node3D:
	var marker := Node3D.new()
	world.add_child(marker)
	marker.add_to_group(CityWorld.ANCHORED_GROUP)
	marker.position = Vector3(128, -100, 128)  # chunk (0, -1, 0)
	return marker


func test_city_stays_loaded_while_inside() -> void:
	var entrance := _place_entrance_marker()
	world.streaming_focus = entrance
	camera.position = entrance.position + Vector3(0, 12000, 0)
	_fill()
	var entrance_chunk := world.origin.absolute_chunk_of(entrance.global_position)
	assert_eq(entrance_chunk, Vector3i(0, -1, 0))
	var expected := {}
	for chunk in world.planner.load_order(entrance_chunk):
		expected[chunk] = true
	assert_eq(_loaded_set(), expected)


func test_origin_follows_the_camera_while_inside() -> void:
	var entrance := _place_entrance_marker()
	world.streaming_focus = entrance
	camera.position = entrance.position + Vector3(0, 12000, 0)
	world.tick()
	for axis in 3:
		assert_lte(absf(camera.position[axis]), 512.0)
	var entrance_chunk := world.origin.absolute_chunk_of(entrance.global_position)
	assert_eq(entrance_chunk, Vector3i(0, -1, 0), "entrance keeps its absolute place")


func test_clearing_the_focus_streams_around_the_camera_again() -> void:
	var entrance := _place_entrance_marker()
	world.streaming_focus = entrance
	world.tick()
	world.streaming_focus = null
	camera.position = Vector3(128 + 256 * 2, -100, 128)
	world.tick()
	assert_eq(world.focus_chunk(), world.origin.absolute_chunk_of(camera.global_position))


func test_roof_bottom_reaches_the_shaders() -> void:
	world.tick()
	var roof_bottom := world.origin.scene_position_of_cell(Vector3i(0, world.config.roof_layer, 0)).y
	assert_almost_eq(float(ChunkView.block_material().get_shader_parameter("roof_bottom_y")), roof_bottom, 0.001)
	assert_almost_eq(float(ChunkView.bridge_material().get_shader_parameter("roof_bottom_y")), roof_bottom, 0.001)
	camera.position += Vector3(0, -700, 0)
	world.tick()
	roof_bottom = world.origin.scene_position_of_cell(Vector3i(0, world.config.roof_layer, 0)).y
	assert_almost_eq(float(ChunkView.block_material().get_shader_parameter("roof_bottom_y")), roof_bottom, 0.001)


func test_loaded_chunks_have_signs_and_lamps() -> void:
	_fill()
	var signs := 0
	var lamps := 0
	for chunk in world.loaded_chunks():
		var view := world.chunk_view(chunk)
		if view != null:
			signs += view.sign_count()
			lamps += view.lamp_count()
	assert_gt(signs, 0)
	assert_gt(lamps, 0)
	assert_gt(world.light_anchors_near(camera.global_position).size(), 0)
