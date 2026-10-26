extends GutTest
## Spec block-interiors: Entering blocks, Climbing stairs, Read-out inside a block.

const EPS := 0.05

var world: CityWorld
var player: Player
var manager: InteriorManager


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
	manager = InteriorManager.new()
	manager.name = "InteriorManager"
	manager.auto_update = false
	world.add_child(manager)
	manager.world_path = NodePath("..")
	manager.player_path = NodePath("../Player")
	add_child_autofree(world)


func _absolute(cell: Vector3i, local: Vector3) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	for axis in 3:
		result.append((cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
	return result


## A bridge ending in an ordinary entrance of block B (its cell_b), 10-30 m long.
func _entrance_bridge() -> BridgeInfo:
	var interiors := InteriorLayout.new(world.layout, world.pocket_layout)
	for x in range(-10, 10):
		for z in range(-10, 10):
			var bridge := world.layout.bridge_between(Vector3i(x, -2, z), Vector3.AXIS_X)
			if bridge == null or bridge.length() < 10.0 or bridge.length() > 30.0:
				continue
			var plan := interiors.plan_of(world.layout.block_at(bridge.cell_b))
			var floor := roundi((bridge.start.y - plan.bottom) / 4.0)
			if plan.has_entrance(floor, Vector3.AXIS_X, -1):
				return bridge
	return null


func _stand_before_entrance(bridge: BridgeInfo, distance: float) -> void:
	var local := bridge.end - Vector3(distance, -0.02, 0)
	world.teleport_focus(_absolute(bridge.cell_a, local))
	player.set_view(-PI * 0.5, 0.0)  # facing +X, towards block B
	world.prime_focus()


func _build(cell: Vector3i) -> InteriorView:
	for i in 40:
		manager.update()
		var view := manager.view_for(cell)
		if view != null and view.is_ready():
			return view
	return manager.view_for(cell)


func test_approaching_a_block() -> void:
	var bridge := _entrance_bridge()
	assert_not_null(bridge)
	_stand_before_entrance(bridge, 5.0)
	var view := _build(bridge.cell_b)
	assert_not_null(view, "the block next to the player should be entered")
	assert_true(view.is_ready())
	var chunk := world.chunk_view(world.layout.chunk_of(bridge.cell_b))
	assert_true(chunk.is_block_hidden(bridge.cell_b))
	assert_false(chunk.is_block_solid(bridge.cell_b))
	assert_lte(manager.active_count(), InteriorManager.MAX_ACTIVE)


func test_walking_in() -> void:
	var bridge := _entrance_bridge()
	_stand_before_entrance(bridge, 5.0)
	_build(bridge.cell_b)
	manager.auto_update = true
	player.move_input = Vector2(0, 1)
	await wait_physics_frames(180)
	var block := world.layout.block_at(bridge.cell_b)
	var local := player.global_position - world.origin.scene_position_of_cell_center(bridge.cell_b)
	assert_true(AABB(block.min_local(), block.size).has_point(local), "the player should be inside the block")
	assert_true(player.is_on_floor())
	assert_almost_eq(local.y, bridge.start.y, EPS)


func test_leaving() -> void:
	var bridge := _entrance_bridge()
	_stand_before_entrance(bridge, 5.0)
	_build(bridge.cell_b)
	_stand_before_entrance(bridge, 60.0)
	manager.update()
	await wait_process_frames(1)
	assert_null(manager.view_for(bridge.cell_b))
	var chunk := world.chunk_view(world.layout.chunk_of(bridge.cell_b))
	assert_false(chunk.is_block_hidden(bridge.cell_b))
	assert_true(chunk.is_block_solid(bridge.cell_b))


func test_up_the_first_flight() -> void:
	var bridge := _entrance_bridge()
	_stand_before_entrance(bridge, 5.0)
	var view := _build(bridge.cell_b)
	var floor_index := view.plan.floor_at(bridge.start.y + 0.1)
	var flight := view.floor(floor_index).flights[0]
	var foot := flight.start - Vector3(0, -0.02, 0.6)  # on the landing, 0.6 m before the first step
	world.teleport_focus(_absolute(bridge.cell_b, foot))
	player.set_view(PI, 0.0)  # facing +Z, up the flight
	world.prime_focus()
	manager.update()
	manager.auto_update = true
	player.move_input = Vector2(0, 1)
	await wait_physics_frames(110)
	var local := player.global_position - world.origin.scene_position_of_cell_center(bridge.cell_b)
	assert_almost_eq(local.y, flight.end.y, 0.3, "the player should reach the landing 2 m up")


## A housing block near the start with a bedroom on floor index 2: [block, bedroom].
func _bedroom_on_floor_2() -> Array:
	var interiors := InteriorLayout.new(world.layout, world.pocket_layout)
	for x in range(-30, 30):
		var block := world.layout.block_at(Vector3i(x, -2, 3))
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		var plan := interiors.plan_of(block)
		if plan.floors < 3:
			continue
		for candidate in interiors.floor_of(plan, 2).rooms:
			if candidate.name == "Bedroom":
				return [block, candidate]
	return []


func _stand_in(found: Array) -> InteriorPlan:
	var target: BlockInfo = found[0]
	var room: RoomInfo = found[1]
	var plan := InteriorLayout.new(world.layout, world.pocket_layout).plan_of(target)
	var centre := room.rect.get_center()
	world.teleport_focus(_absolute(target.cell, Vector3(centre.x, plan.floor_y(2) + 0.05, centre.y)))
	world.prime_focus()
	_build(target.cell)
	return plan


func test_read_out_in_a_room() -> void:
	var found := _bedroom_on_floor_2()
	assert_false(found.is_empty())
	var plan := _stand_in(found)
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.world_path = hud.get_path_to(world)
	hud.camera_path = hud.get_path_to(player)
	hud.interiors_path = hud.get_path_to(manager)
	hud.refresh()
	assert_string_contains(hud.text(), "Floor 3 of %d" % plan.floors)
	assert_string_contains(hud.text(), "Bedroom")


func test_light_where_the_player_is() -> void:
	var found := _bedroom_on_floor_2()
	assert_false(found.is_empty())
	var plan := _stand_in(found)
	var bedroom: RoomInfo = found[1]
	var centre := world.origin.scene_position_of_cell_center(plan.block.cell)
	var lights := CityLights.new()
	add_child_autofree(lights)
	lights.world_path = lights.get_path_to(world)
	lights.viewer_path = lights.get_path_to(player)
	lights.interiors_path = lights.get_path_to(manager)
	lights.refresh()
	var lit := false
	for light in lights.active_lights():
		var local := light.global_position - centre
		if bedroom.rect.has_point(Vector2(local.x, local.z)) and local.y > plan.floor_y(2) and local.y < plan.floor_y(3):
			lit = true
	assert_true(lit, "a pool light should hang in the bedroom")
	var anchors := manager.light_anchors()
	assert_gt(anchors.size(), 0)
	for anchor in anchors:
		var y := anchor.position.y - centre.y
		assert_between(y, plan.floor_y(2), plan.floor_y(3), "room lights only from the player's floor")
