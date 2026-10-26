extends GutTest
## Spec on-foot-movement, exercised with real physics: walking/flying, solid city, railings,
## fall safety net.

const EPS := 0.05

var world: CityWorld
var player: Player


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
	add_child_autofree(world)


## A bridge of 12-24 m between two blocks without magic doorways on the facing sides.
func _bridge() -> BridgeInfo:
	var pockets := world.pocket_layout
	for x in range(-10, 10):
		for z in range(-10, 10):
			var bridge := world.layout.bridge_between(Vector3i(x, -2, z), Vector3.AXIS_X)
			if bridge == null or bridge.length() < 12.0 or bridge.length() > 24.0:
				continue
			var door_a := pockets.doorway_of(bridge.cell_a)
			var door_b := pockets.doorway_of(bridge.cell_b)
			if (door_a != null and door_a.face_axis == Vector3.AXIS_X) or (door_b != null and door_b.face_axis == Vector3.AXIS_X):
				continue
			return bridge
	return null


func _absolute(cell: Vector3i, local: Vector3) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	for axis in 3:
		result.append((cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
	return result


## Puts the feet on the deck at `along` (0..1) of its length and `lateral` metres off its centre line.
func _place_on_deck(bridge: BridgeInfo, along: float, lateral: float = 0.0) -> void:
	var local := bridge.start.lerp(bridge.end, along) + Vector3(0, 0.02, lateral)
	world.teleport_focus(_absolute(bridge.cell_a, local))
	player.set_view(-PI * 0.5, 0.0)  # face +X, along the bridge
	world.prime_focus()


## Scene position of a point given relative to a cell centre.
func _scene(cell: Vector3i, local: Vector3) -> Vector3:
	return world.origin.scene_position_of_cell_center(cell) + local


func test_toggle() -> void:
	assert_eq(player.mode, Player.Mode.WALK)
	player.toggle_mode()
	assert_eq(player.mode, Player.Mode.FLY)
	player.toggle_mode()
	assert_eq(player.mode, Player.Mode.WALK)


func test_standing_on_a_bridge() -> void:
	var bridge := _bridge()
	assert_not_null(bridge)
	_place_on_deck(bridge, 0.5)
	await wait_physics_frames(60)
	assert_true(player.is_on_floor())
	var deck_y := _scene(bridge.cell_a, bridge.start).y
	assert_almost_eq(player.global_position.y, deck_y, EPS)


func test_walls_stop_the_player() -> void:
	var bridge := _bridge()
	_place_on_deck(bridge, 0.5)
	player.move_input = Vector2(0, 1)
	player.wants_sprint = true
	await wait_physics_frames(150)
	var face_x := _scene(bridge.cell_a, bridge.end).x
	assert_lte(player.global_position.x, face_x)
	assert_gte(player.global_position.x, face_x - 1.0, "the player should have reached the face")


func test_railings_hold_the_player() -> void:
	var bridge := _bridge()
	_place_on_deck(bridge, 0.5)
	player.move_input = Vector2(1, 0)  # sideways (towards +Z when facing +X)
	player.wants_sprint = true
	await wait_physics_frames(180)
	var centre := _scene(bridge.cell_a, bridge.start)
	assert_lt(absf(player.global_position.z - centre.z), bridge.width * 0.5)
	assert_almost_eq(player.global_position.y, centre.y, EPS)


func test_flight_ignores_walls() -> void:
	var bridge := _bridge()
	_place_on_deck(bridge, 0.7)
	player.set_mode(Player.Mode.FLY)
	player.fly_input = Vector3(0, 0, -1)
	await wait_physics_frames(60)
	var face_x := _scene(bridge.cell_a, bridge.end).x
	assert_gt(player.global_position.x, face_x + 5.0, "flight should pass through the block")


func test_fall_safety_net() -> void:
	var bridge := _bridge()
	player.fall_guard.limit_seconds = 0.5
	_place_on_deck(bridge, 0.5)
	await wait_physics_frames(40)
	var safe := player.global_position
	player.global_position += Vector3(0, 0, 40)  # off the bridge, into the open
	await wait_physics_frames(10)
	assert_lt(player.global_position.y, safe.y, "the player should be falling")
	await wait_physics_frames(50)
	assert_almost_eq(player.global_position, safe, Vector3.ONE * 0.1)
