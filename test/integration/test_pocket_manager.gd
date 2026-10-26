extends GutTest
## Specs pocket-spaces and portal-traversal, exercised through CityWorld + PocketManager.

const EPS := 0.01

var world: CityWorld
var fly: FlyCamera
var manager: PocketManager


func before_each() -> void:
	world = CityWorld.new()
	world.config = CityConfig.new()
	world.radius_h = 2
	world.radius_v = 1
	world.chunks_per_tick = 64
	world.auto_tick = false
	fly = FlyCamera.new()
	fly.name = "FlyCamera"
	fly.input_enabled = false
	world.add_child(fly)
	world.focus_path = NodePath("FlyCamera")
	manager = PocketManager.new()
	manager.name = "PocketManager"
	manager.auto_update = false
	world.add_child(manager)
	manager.world_path = NodePath("..")
	manager.camera_path = NodePath("../FlyCamera")
	add_child_autofree(world)


func _fill() -> void:
	for i in 50:
		if world.is_streaming_complete():
			return
		world.tick()


## A doorway near the roof that is the nearest doorway to the point `distance` m in front of it.
func _approach_lonely_doorway(distance: float) -> DoorwayInfo:
	for cx in range(-2, 3):
		for cz in range(-2, 3):
			for doorway in world.pocket_layout.doorways_in_chunk(Vector3i(cx, -1, cz)):
				manager.place_camera_before(doorway, distance)
				_fill()
				var nearest := manager.nearest_doorway_view(PocketManager.ACTIVATION_RADIUS)
				if nearest != null and nearest.doorway.cell == doorway.cell:
					return doorway
	return null


func _outer_xf() -> Transform3D:
	return manager.active_doorway().global_transform


func _inner_xf() -> Transform3D:
	return manager.interior().inner_door_global()


func test_doorway_views_per_chunk() -> void:
	fly.global_position = Vector3(128, -100, 128)
	_fill()
	var total := 0
	for chunk in world.loaded_chunks():
		var view := world.chunk_view(chunk)
		var expected := world.pocket_layout.doorways_in_chunk(chunk)
		if view == null:
			assert_eq(expected.size(), 0)
			continue
		var views := view.doorway_views()
		assert_eq(views.size(), expected.size())
		for i in views.size():
			total += 1
			var doorway := expected[i]
			var expected_xf := Transform3D(doorway.door.basis,
					world.origin.scene_position_of_cell_center(doorway.cell) + doorway.door.origin)
			assert_almost_eq(views[i].global_transform.origin, expected_xf.origin, Vector3.ONE * 0.001)
			assert_almost_eq(views[i].global_transform.basis.z, expected_xf.basis.z, Vector3.ONE * 0.001)
	assert_gt(total, 0)
	assert_eq(world.doorway_views().size(), total)


func test_approaching_a_doorway() -> void:
	var doorway := _approach_lonely_doorway(30.0)
	assert_not_null(doorway)
	manager.update()
	assert_not_null(manager.active_doorway())
	assert_eq(manager.active_doorway().doorway.cell, doorway.cell)
	assert_eq(get_tree().get_nodes_in_group(PocketManager.INTERIOR_GROUP).size(), 1)
	assert_eq(manager.pocket_info().cell, doorway.cell)


func test_leaving_the_area() -> void:
	assert_not_null(_approach_lonely_doorway(30.0))
	manager.update()
	world.teleport_focus(PackedFloat64Array([0.0, 2000.0, 0.0]))  # far above the sky layers
	_fill()
	manager.update()
	await wait_process_frames(1)
	assert_null(manager.active_doorway())
	assert_eq(get_tree().get_nodes_in_group(PocketManager.INTERIOR_GROUP).size(), 0)


func test_out_of_sight() -> void:
	assert_not_null(_approach_lonely_doorway(30.0))
	manager.update()
	var door := _outer_xf().origin
	var pocket := manager.pocket_info()
	var interior := manager.interior()
	var half := pocket.size * 0.5
	for corner: Vector3 in [Vector3(-half.x, 0, -half.z), Vector3(half.x, 0, -half.z), Vector3(-half.x, pocket.size.y, half.z),
			Vector3(half.x, pocket.size.y, half.z), Vector3(-half.x, 0, half.z), Vector3(half.x, pocket.size.y, -half.z)]:
		var p := interior.global_transform * corner
		assert_gt(p.distance_to(door), 6000.0, "pocket corner %s too close to the city" % p)


func test_interior_is_on_the_pocket_layer() -> void:
	assert_not_null(_approach_lonely_doorway(30.0))
	manager.update()
	for node in manager.interior().find_children("*", "VisualInstance3D", true, false):
		assert_eq((node as VisualInstance3D).layers, PocketManager.POCKET_LAYERS, "%s not on the pocket layer" % node.name)


func test_portal_camera_follows_the_viewer() -> void:
	assert_not_null(_approach_lonely_doorway(30.0))
	manager.update()
	var expected := PortalMath.pair(_outer_xf(), _inner_xf()) * fly.camera.global_transform
	var actual := manager.portal_camera().global_transform
	assert_almost_eq(actual.origin, expected.origin, Vector3.ONE * 0.01)
	for axis in 3:
		assert_almost_eq(actual.basis[axis], expected.basis[axis], Vector3.ONE * 0.001)
	assert_eq(manager.portal_camera().cull_mask, PocketManager.POCKET_LAYERS)


func _enter() -> DoorwayInfo:
	var doorway := _approach_lonely_doorway(1.0)
	manager.update()
	fly.global_position = _outer_xf() * Vector3(0, 3, -1)
	manager.update()
	return doorway


func test_entering_a_pocket_space() -> void:
	var doorway := _approach_lonely_doorway(1.0)
	assert_not_null(doorway)
	manager.update()
	var outer := _outer_xf()
	var view_before := fly.camera.global_transform.basis * Vector3(0, 0, -1)
	fly.global_position = outer * Vector3(0, 3, -1)
	manager.update()
	assert_true(manager.is_inside())
	var inner := _inner_xf()
	assert_almost_eq(fly.global_position, inner * Vector3(0, 3, 1), Vector3.ONE * EPS)
	var view_after := fly.camera.global_transform.basis * Vector3(0, 0, -1)
	var mapped_view := PortalMath.pair(outer, inner).basis * view_before
	assert_almost_eq(view_after, mapped_view, Vector3.ONE * 0.001)
	assert_eq(world.streaming_focus, manager.active_doorway())


func test_origin_follows_the_camera_into_the_pocket() -> void:
	assert_not_null(_enter())
	world.tick()
	for axis in 3:
		assert_lte(absf(fly.global_position[axis]), 512.0)
	assert_true(manager.is_inside())


func test_looking_back_at_the_city_from_inside() -> void:
	assert_not_null(_enter())
	world.tick()
	manager.update()
	var expected := PortalMath.pair(_inner_xf(), _outer_xf()) * fly.camera.global_transform
	var actual := manager.portal_camera().global_transform
	assert_almost_eq(actual.origin, expected.origin, Vector3.ONE * 0.01)
	assert_eq(manager.portal_camera().cull_mask, PocketManager.CITY_LAYERS)


func test_city_stays_loaded_while_inside() -> void:
	assert_not_null(_enter())
	_fill()
	var entrance_chunk := world.origin.absolute_chunk_of(manager.active_doorway().global_position)
	assert_true(world.loaded_chunks().has(entrance_chunk))
	assert_eq(world.focus_chunk(), entrance_chunk)


func test_leaving_a_pocket_space() -> void:
	assert_not_null(_enter())
	world.tick()
	manager.update()
	fly.global_position = _inner_xf() * Vector3(0, 3, 1)
	manager.update()
	fly.global_position = _inner_xf() * Vector3(0, 3, -1)
	manager.update()
	assert_false(manager.is_inside())
	assert_almost_eq(fly.global_position, _outer_xf() * Vector3(0, 3, 1), Vector3.ONE * EPS)
	assert_null(world.streaming_focus)


func test_crossing_from_behind_does_nothing() -> void:
	var doorway := _approach_lonely_doorway(30.0)
	assert_not_null(doorway)
	manager.update()
	manager.place_camera_before(doorway, -1.0)  # a teleport, not a crossing
	manager.update()
	var outer := _outer_xf()
	assert_almost_eq(fly.global_position, outer * Vector3(0, 3, -1), Vector3.ONE * EPS)
	fly.global_position = outer * Vector3(0, 3, 1)
	manager.update()
	assert_false(manager.is_inside())
	assert_almost_eq(fly.global_position, outer * Vector3(0, 3, 1), Vector3.ONE * EPS)


func test_crossing_beside_the_opening_does_nothing() -> void:
	assert_not_null(_approach_lonely_doorway(30.0))
	manager.update()
	var outer := _outer_xf()
	fly.global_position = outer * Vector3(5, 3, 1)
	manager.update()
	fly.global_position = outer * Vector3(5, 3, -1)
	manager.update()
	assert_false(manager.is_inside())
	assert_almost_eq(fly.global_position, outer * Vector3(5, 3, -1), Vector3.ONE * EPS)


func test_stepping_through_from_a_distance_lands_inside_the_room() -> void:
	assert_not_null(_approach_lonely_doorway(14.0))
	manager.update()
	manager.enter()
	assert_true(manager.is_inside())
	var local := _inner_xf().affine_inverse() * fly.global_position
	assert_between(local.z, 0.0, 1.0, "camera should stand just inside the room")
	assert_almost_eq(local.y, 3.0, EPS)


func test_nothing_in_front_of_the_far_door_blocks_the_view() -> void:
	assert_not_null(_approach_lonely_doorway(30.0))
	manager.update()
	assert_between(manager.portal_camera().near, 29.0, 30.0)


func test_near_plane_falls_back_when_the_door_is_beside_the_camera() -> void:
	assert_not_null(_approach_lonely_doorway(30.0))
	manager.update()
	fly.set_view(fly.yaw + PI * 0.5, 0.0)  # door is now off to the side
	manager.update()
	assert_lte(manager.portal_camera().near, fly.camera.near + 0.001)
