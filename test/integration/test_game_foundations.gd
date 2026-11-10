extends GutTest
## Specs game-time (The Light's day and night), interaction, save-games, content-data
## (Background jobs) on the main scene and a small world.

const MAIN_SCENE := "res://src/scenes/main.tscn"


func _main() -> Node3D:
	var main := (load(MAIN_SCENE) as PackedScene).instantiate() as Node3D
	add_child_autofree(main)
	await wait_process_frames(2)
	return main


func test_the_sun_follows_the_clock() -> void:
	var main := await _main()
	var session := main.get_node("GameSession") as GameSession
	var world := main.get_node("CityWorld") as CityWorld
	var sun := main.get_node("Sun") as DirectionalLight3D
	session.clock.total_minutes = 517 * GameClock.MINUTES_PER_YEAR + 2 * 60
	session.refresh()
	world.tick()
	assert_almost_eq(sun.light_energy, 0.0, 1e-4)
	session.clock.total_minutes = 517 * GameClock.MINUTES_PER_YEAR + 12 * 60
	session.refresh()
	world.tick()
	assert_almost_eq(sun.light_energy, Atmosphere.light_energy(world.focus_depth_layers()), 1e-4)


func test_key_bindings() -> void:
	var interact_keys: Array[int] = []
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			interact_keys.append((event as InputEventKey).physical_keycode)
	assert_has(interact_keys, KEY_E)
	for event in InputMap.action_get_events("move_up"):
		if event is InputEventKey:
			assert_ne((event as InputEventKey).physical_keycode, KEY_E)


# --- A small world with an entered block -------------------------------------------------

var world: CityWorld
var player: Player
var manager: InteriorManager
var interaction: Interaction


func _small_world() -> void:
	world = CityWorld.new()
	world.config = CityConfig.new()
	world.radius_h = 1
	world.radius_v = 1
	world.auto_tick = false
	player = Player.new()
	player.name = "Player"
	player.input_enabled = false
	player.start_mode = Player.Mode.FLY
	world.add_child(player)
	world.focus_path = NodePath("Player")
	manager = InteriorManager.new()
	manager.name = "InteriorManager"
	manager.auto_update = false
	world.add_child(manager)
	manager.world_path = NodePath("..")
	manager.player_path = NodePath("../Player")
	interaction = Interaction.new()
	interaction.name = "Interaction"
	world.add_child(interaction)
	interaction.player_path = NodePath("../Player")
	interaction.interiors_path = NodePath("../InteriorManager")
	add_child_autofree(world)


## Stands 1.5 m in front of the door of a non-core unit on floor index 1, facing it.
func _face_a_door() -> InteriorUnit:
	var interiors := InteriorLayout.new(world.layout, world.pocket_layout)
	for x in range(-20, 20):
		var block := world.layout.block_at(Vector3i(x, -2, 3))
		if block == null:
			continue
		var plan := interiors.plan_of(block)
		for unit in plan.units:
			if unit.is_core:
				continue
			var local := Vector3(unit.door_x, plan.floor_y(1) + 0.02, unit.front_z() + unit.front_sign * 1.5)
			var absolute := PackedFloat64Array()
			for axis in 3:
				absolute.append((block.cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
			world.teleport_focus(absolute)
			player.set_view(0.0 if unit.front_sign > 0 else PI, 0.0)
			world.prime_focus()
			for i in 40:
				manager.update()
			return unit
	return null


func test_facing_a_door() -> void:
	_small_world()
	var unit := _face_a_door()
	assert_not_null(unit)
	interaction.refresh()
	var target := interaction.target()
	assert_false(target.is_empty(), "a door should be the target")
	assert_eq(target.get("kind"), "door")
	assert_string_contains(str(target.get("label")), "Fl 2")
	assert_string_contains(str(target.get("label")), "Unit %d" % (unit.index + 1))


func test_looking_away() -> void:
	_small_world()
	_face_a_door()
	player.set_view(player.yaw + PI, 0.0)
	interaction.refresh()
	assert_true(interaction.target().is_empty())


func test_prompt_follows_the_target() -> void:
	_small_world()
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.interaction_path = hud.get_path_to(interaction)
	_face_a_door()
	interaction.refresh()
	hud.refresh_prompt()
	assert_string_starts_with(hud.prompt_text(), "E · ")
	assert_string_contains(hud.prompt_text(), "Fl 2")
	player.set_view(player.yaw + PI, 0.0)
	interaction.refresh()
	hud.refresh_prompt()
	assert_eq(hud.prompt_text(), "")


func test_interacting_emits_the_target() -> void:
	_small_world()
	_face_a_door()
	interaction.refresh()
	watch_signals(interaction)
	interaction.interact()
	assert_signal_emitted(interaction, "interacted")


# --- Saves --------------------------------------------------------------------------------

func _session() -> GameSession:
	var session := GameSession.new()
	session.name = "GameSession"
	world.add_child(session)
	session.world_path = NodePath("..")
	session.player_path = NodePath("../Player")
	return session


func _place(absolute: PackedFloat64Array) -> void:
	world.teleport_focus(absolute)
	player.set_view(1.25, -0.4)


func test_round_trip() -> void:
	_small_world()
	var session := _session()
	_place(PackedFloat64Array([1234.5, -1300.25, -777.75]))
	player.set_mode(Player.Mode.FLY)
	session.clock.total_minutes = 517 * GameClock.MINUTES_PER_YEAR + 3 * GameClock.MINUTES_PER_DAY + 1234
	var saved := session.to_dict()
	var minutes := session.clock.total_minutes
	_place(PackedFloat64Array([0.0, 100.0, 0.0]))
	player.set_view(0.0, 0.0)
	player.set_mode(Player.Mode.WALK)
	session.clock.add_minutes(500)
	var fresh := _session()
	assert_eq(fresh.from_dict(saved), "")
	assert_eq(fresh.clock.total_minutes, minutes)
	assert_eq(player.mode, Player.Mode.FLY)
	assert_almost_eq(player.yaw, 1.25, 1e-5)
	assert_almost_eq(player.pitch, -0.4, 1e-5)
	var at := world.origin.absolute_metres(player.global_position)
	assert_almost_eq(at[0], 1234.5, 0.01)
	assert_almost_eq(at[1], -1300.25, 0.01)
	assert_almost_eq(at[2], -777.75, 0.01)


func test_deep_positions_keep_their_precision() -> void:
	_small_world()
	var session := _session()
	_place(PackedFloat64Array([12.34, -640000123.45, 98.76]))
	var saved := JSON.parse_string(JSON.stringify(session.to_dict())) as Dictionary
	_place(PackedFloat64Array([0.0, 0.0, 0.0]))
	assert_eq(session.from_dict(saved), "")
	var at := world.origin.absolute_metres(player.global_position)
	assert_almost_eq(at[0], 12.34, 0.01)
	assert_almost_eq(at[1], -640000123.45, 0.01)
	assert_almost_eq(at[2], 98.76, 0.01)


func test_unknown_versions_are_refused() -> void:
	_small_world()
	var session := _session()
	var saved := session.to_dict()
	saved["version"] = GameSession.SAVE_VERSION + 1
	var minutes := session.clock.total_minutes
	session.clock.add_minutes(10)
	var error := session.from_dict(saved)
	assert_ne(error, "")
	assert_eq(session.clock.total_minutes, minutes + 10)


func test_save_files() -> void:
	_small_world()
	var session := _session()
	_place(PackedFloat64Array([50.0, -600.0, 70.0]))
	assert_eq(session.save_to_slot("gut_test"), "")
	_place(PackedFloat64Array([0.0, 0.0, 0.0]))
	assert_eq(session.load_from_slot("gut_test"), "")
	var at := world.origin.absolute_metres(player.global_position)
	assert_almost_eq(at[1], -600.0, 0.01)
	DirAccess.remove_absolute(GameSession.slot_path("gut_test"))


# --- Background jobs ----------------------------------------------------------------------

func test_computed_once() -> void:
	var jobs := BackgroundJobs.new()
	add_child_autofree(jobs)
	var runs: Array[int] = [0]
	var job := func() -> Variant:
		runs[0] += 1
		return 42
	for i in 3:
		jobs.submit("answer", job)
	for i in 200:
		jobs.poll()
		if jobs.is_ready("answer"):
			break
		await wait_process_frames(1)
	assert_true(jobs.is_ready("answer"))
	assert_eq(jobs.result("answer"), 42)
	assert_eq(runs[0], 1)
