extends GutTest
## Specs story-director (Story runner) and dialogue (Scene panel) on a small world.

var world: CityWorld
var session: GameSession
var jobs: JobManager
var panel: DialoguePanel
var runner: StoryRunner
var patron: WorkplaceInfo


func before_each() -> void:
	world = CityWorld.new()
	world.config = CityConfig.new()
	world.radius_h = 1
	world.radius_v = 1
	world.auto_tick = false
	var player := Player.new()
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
	panel = DialoguePanel.new()
	panel.name = "DialoguePanel"
	world.add_child(panel)
	runner = StoryRunner.new()
	runner.name = "StoryRunner"
	runner.auto_update = false
	world.add_child(runner)
	runner.world_path = NodePath("..")
	runner.session_path = NodePath("../GameSession")
	runner.jobs_path = NodePath("../JobManager")
	runner.panel_path = NodePath("../DialoguePanel")
	add_child_autofree(world)
	var market := world.population.job_market(Vector3i(0, -3, 0))
	for i in market.active_indices():
		var w := market.workplace(i)
		if w.is_food:
			patron = w
			break
	jobs.set_patron(patron)
	runner.cast_now(world, patron)


func _door(cell: Vector3i, floor_index: int, unit: int) -> Dictionary:
	return {"kind": "door", "payload": {"cell": cell, "floor": floor_index, "unit": unit}}


func _deliver(job: DeliveryJob) -> void:
	jobs._on_interacted(_door(job.dropoff_cell, job.dropoff_floor, job.dropoff_unit))


## One step of play: answer an open scene with `pick`, deliver a story job, or run an order.
func _step(pick: Callable) -> void:
	runner.update()
	if panel.is_open():
		var count := StoryDirector.choices(runner.plot, runner.state).size()
		panel.choose(mini(pick.call(runner.state.scene), count - 1))
		return
	for job in jobs.carried:
		if not job.story_beat.is_empty():
			_deliver(job)
			return
	jobs._on_interacted(_door(patron.cell, patron.floor_index, patron.unit))
	for job in jobs.carried:
		if job.story_beat.is_empty():
			_deliver(job)
			return
	session.clock.add_minutes(60)


func _play_until(flag_or_scene: String, pick: Callable, steps: int = 120) -> void:
	for i in steps:
		if runner.state.flags.has(flag_or_scene) or runner.state.scene == flag_or_scene:
			return
		_step(pick)


func test_acts_1_and_2_on_deliveries_and_choices() -> void:
	for first_choice in 2:
		var pick := func(_scene: String) -> int: return first_choice
		runner.state = StoryState.new()
		runner.cast_now(world, patron)
		jobs.carried.clear()
		jobs.completed = 0
		_play_until("act2_done", pick, 200)
		var state := runner.state
		assert_true(state.flags.has("act2_done"), "choice %d reaches the end of Act 2" % first_choice)
		assert_eq(state.act, 2)
		var order: Array[String] = []
		for b: Dictionary in runner.plot["beats"]:
			if state.done.has(b["id"]):
				order.append(b["id"])
		assert_has(order, "first_night")
		assert_has(order, "blight")
		assert_has(order, "keeper_call")
		assert_true(state.done.has("ration_keeper") != state.done.has("ration_friend"), "exactly one ration delivery")
		assert_lte(int(state.done["first_night"]), int(state.done["blight"]))
		assert_lte(int(state.done["blight"]), int(state.done["keeper_call"]))


func test_saved_story() -> void:
	var pick := func(_scene: String) -> int: return 0
	_play_until("rival", pick)
	var saved := JSON.parse_string(JSON.stringify(session.to_dict())) as Dictionary
	var before := JSON.stringify(runner.state.to_dict())
	runner.state = StoryState.new()
	assert_eq(session.from_dict(saved), "")
	assert_eq(JSON.stringify(runner.state.to_dict()), before)
	assert_eq(runner.state.scene, "rival")


func test_picking_a_choice() -> void:
	var pick := func(_scene: String) -> int: return 0
	_play_until("rival", pick)
	runner.update()
	assert_true(panel.is_open())
	assert_string_contains(panel.text(), runner.state.cast["rival"]["first"])
	panel.choose(1)
	assert_false(panel.is_open())
	assert_true(runner.state.flags.has("rival_grudge"))
	assert_false(runner.state.flags.has("rival_friendly"))
