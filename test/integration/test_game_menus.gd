extends GutTest
## Spec game-menus: Main menu, Settings, Address book, Ambience.

const TEST_SETTINGS := "user://test_settings.cfg"

var world: CityWorld
var player: Player
var session: GameSession
var jobs: JobManager
var menu: GameMenu


func before_each() -> void:
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
	session = GameSession.new()
	session.name = "GameSession"
	session.running = false
	world.add_child(session)
	session.world_path = NodePath("..")
	session.player_path = NodePath("../Player")
	jobs = JobManager.new()
	jobs.name = "JobManager"
	world.add_child(jobs)
	jobs.world_path = NodePath("..")
	jobs.session_path = NodePath("../GameSession")
	menu = GameMenu.new()
	menu.name = "GameMenu"
	menu.settings_path = TEST_SETTINGS
	menu.session_path = NodePath("../GameSession")
	menu.player_path = NodePath("../Player")
	world.add_child(menu)
	add_child_autofree(world)


func after_each() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)


func test_new_game_with_a_named_courier() -> void:
	menu.open()
	assert_true(menu.is_open())
	assert_false(session.running)
	watch_signals(menu)
	menu.new_game("Mara Quill", "she/her")
	assert_false(menu.is_open())
	assert_true(session.running)
	assert_true(player.input_enabled)
	assert_signal_emitted(menu, "started")
	var saved := JSON.parse_string(JSON.stringify(session.to_dict())) as Dictionary
	assert_eq(saved["courier_profile"]["name"], "Mara Quill")
	var state := StoryState.new()
	state.cast = {"patron": {"first": "Ada", "family": "Lin", "place": "Ada's Noodles"}}
	state.scene = "first_night"
	var text := StoryDirector.scene_text(StoryDirector.template(), state, 3, menu.profile)
	assert_string_contains(text, "Mara Quill")


func test_settings_are_kept() -> void:
	menu.apply_settings(0.004, 2.0, 0.5)
	assert_almost_eq(player.model.mouse_sensitivity, 0.004, 0.00001)
	assert_almost_eq(session.clock.speed, 2.0, 0.0001)
	var again := GameSettings.new()
	again.load_from(TEST_SETTINGS)
	assert_almost_eq(again.mouse_sensitivity, 0.004, 0.00001)
	assert_almost_eq(again.game_speed, 2.0, 0.0001)
	assert_almost_eq(again.volume, 0.5, 0.0001)


func test_address_book() -> void:
	var market := world.population.job_market(Vector3i(0, -3, 0))
	var patron: WorkplaceInfo = null
	for i in market.active_indices():
		if market.workplace(i).is_food:
			patron = market.workplace(i)
			break
	jobs.set_patron(patron)
	jobs.home = {"cell": patron.cell, "floor": 0, "unit": 1}
	var book := AddressBook.new()
	book.name = "AddressBook"
	world.add_child(book)
	book.jobs_path = NodePath("../JobManager")
	var lines := book.entries()
	assert_eq(lines.size(), 2)
	assert_string_contains(lines[0], patron.name)
	assert_string_contains(lines[0], Address.format(jobs.names, patron.cell, patron.floor_index, patron.unit))
	assert_string_contains(lines[1], "Home")


func test_ambience_follows_depth() -> void:
	var high := Ambience.levels_for(0.0)
	var deep := Ambience.levels_for(20.0)
	assert_gt(deep.x, high.x, "louder below")
	assert_lt(deep.y, high.y, "darker below")


func test_sleeping_at_home_saves() -> void:
	var rest := HomeRest.new()
	rest.name = "HomeRest"
	world.add_child(rest)
	rest.session_path = NodePath("../GameSession")
	rest.jobs_path = NodePath("../JobManager")
	session.clock.total_minutes = GameClock.new_game().day_number() * GameClock.MINUTES_PER_DAY + 22 * 60
	assert_eq(rest.sleep(), "")
	assert_eq(session.clock.minute_of_day(), HomeRest.WAKE_MINUTE)
	assert_eq(session.clock.day_number(), GameClock.new_game().day_number() + 1)
	var slots := GameSession.list_slots()
	var found := false
	for entry in slots:
		found = found or entry["slot"] == HomeRest.SLOT
	assert_true(found, "the autosave is listed")
	DirAccess.remove_absolute(GameSession.slot_path(HomeRest.SLOT))


func test_save_slots_in_the_menu() -> void:
	var slot := menu.save_new_slot()
	assert_ne(slot, "")
	assert_eq(GameSession.list_slots()[0]["slot"], slot, "newest first")
	session.clock.add_minutes(500)
	assert_eq(menu.load_slot(slot), "")
	assert_false(menu.is_open())
	DirAccess.remove_absolute(GameSession.slot_path(slot))


func test_rebinding_a_key() -> void:
	menu.open()
	menu.rebinding = "interact"
	menu.press_key_for_rebinding(KEY_Y)
	assert_eq(menu.rebinding, "")
	var keys := []
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	assert_eq(keys, [KEY_Y])
	var again := GameSettings.new()
	again.load_from(TEST_SETTINGS)
	assert_eq(int(again.bindings["interact"]), KEY_Y)
	GameSettings.apply_binding("interact", KEY_E)


func test_fog_limited_streaming() -> void:
	world.radius_h = 4
	world.fog_radius_h = 2
	var roof := PackedFloat64Array([0.0, (world.config.roof_layer + 1) * world.config.cell_size.y + 30.0, 0.0])
	world.teleport_focus(roof)
	assert_eq(world.effective_radius_h(), 4, "clear air above the roof")
	var deep := PackedFloat64Array([0.0, (world.config.roof_layer - 6) * world.config.cell_size.y, 0.0])
	world.teleport_focus(deep)
	assert_eq(world.effective_radius_h(), 2, "the fog hides what lies further")
	world.tick()
	assert_eq(world.planner.radius_h, 2)
	world.chunks_per_tick = 64
	for i in 20:
		world.tick()
		if world.is_streaming_complete():
			break
	assert_true(world.is_streaming_complete(), "streaming settles in the fog instead of loading and unloading forever")
	for chunk in world.loaded_chunks():
		assert_lte(world.planner.region_distance(chunk - world.focus_chunk(), 3, world.radius_v + 1), 1.0)
