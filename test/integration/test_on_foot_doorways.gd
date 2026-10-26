extends GutTest
## Specs portal-traversal (Doorways can be walked through) and pocket-spaces (Solid pocket spaces).

var world: CityWorld
var player: Player
var manager: PocketManager


func before_each() -> void:
	world = CityWorld.new()
	world.config = CityConfig.new()
	world.radius_h = 1
	world.radius_v = 1
	world.chunks_per_tick = 64
	world.auto_tick = false
	player = Player.new()
	player.name = "Player"
	player.input_enabled = false
	player.start_mode = Player.Mode.WALK
	world.add_child(player)
	world.focus_path = NodePath("Player")
	manager = PocketManager.new()
	manager.name = "PocketManager"
	world.add_child(manager)
	manager.world_path = NodePath("..")
	manager.camera_path = NodePath("../Player")
	add_child_autofree(world)


## A magic doorway standing on a bridge deck near the roof.
func _bridge_doorway() -> DoorwayInfo:
	for x in range(-12, 12):
		for z in range(-12, 12):
			for y: int in [-2, -1, -3]:
				var doorway := world.pocket_layout.doorway_of(Vector3i(x, y, z))
				if doorway != null and doorway.on_bridge:
					return doorway
	return null


func test_walking_into_a_doorway() -> void:
	var doorway := _bridge_doorway()
	assert_not_null(doorway)
	manager.place_camera_before(doorway, 4.0, WalkModel.EYE_HEIGHT + 0.02)
	world.prime_focus()
	player.move_input = Vector2(0, 1)
	for i in 240:
		await wait_physics_frames(1)
		if manager.is_inside():
			break
	assert_true(manager.is_inside(), "walking forward should carry the player through the doorway")
	player.move_input = Vector2.ZERO
	await wait_physics_frames(60)
	assert_true(player.is_on_floor())
	var floor_y := manager.interior().inner_door_global().origin.y
	assert_almost_eq(player.global_position.y, floor_y, 0.05)


func test_the_inner_door_is_open() -> void:
	var doorway := _bridge_doorway()
	var pocket := world.pocket_layout.pocket_of(doorway)
	var interior := PocketInterior.new()
	add_child_autofree(interior)
	interior.build(pocket, doorway)
	var half_depth := pocket.size.z * 0.5
	var opening := AABB(Vector3(-2, 0, -half_depth - 1.0), Vector3(4, 6, 1.5)).grow(-0.01)
	var boxes := interior.collision_boxes()
	assert_gt(boxes.size(), 6)
	for box in boxes:
		assert_false(box.intersects(opening), "%s blocks the inner door" % box)
	var floor_found := false
	for box in boxes:
		floor_found = floor_found or box.has_point(Vector3(0, -0.2, 0))
	assert_true(floor_found, "the pocket space needs a floor")
