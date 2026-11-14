extends GutTest
## Spec transit: Riding the hubs, Taking the lift, on a small world.

var world: CityWorld
var player: Player
var session: GameSession
var jobs: JobManager
var panel: DialoguePanel
var transit: TransitDirector


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
	panel = DialoguePanel.new()
	panel.name = "DialoguePanel"
	world.add_child(panel)
	transit = TransitDirector.new()
	transit.name = "TransitDirector"
	world.add_child(transit)
	transit.world_path = NodePath("..")
	transit.player_path = NodePath("../Player")
	transit.session_path = NodePath("../GameSession")
	transit.jobs_path = NodePath("../JobManager")
	transit.panel_path = NodePath("../DialoguePanel")
	add_child_autofree(world)
	transit._setup()


func _absolute_cell(scene_position: Vector3) -> Vector3i:
	return world.origin.absolute_cell_of(scene_position)


func test_riding_to_a_neighbouring_district() -> void:
	var from := world.layout.district_of(SpawnFinder.find_on_foot(world.layout).cell) + Vector3i(0, -1, 0)
	var hub := transit.network.hub_of(from)
	jobs.courier.wallet.credits = 100
	var minutes := session.clock.total_minutes
	transit.open_hub(hub["cell"])
	assert_true(panel.is_open())
	assert_gt(transit.choices.size(), 3)
	var choice: Dictionary = transit.choices[0]
	var to: Vector3i = choice["to"]
	panel.choose(0)
	var target: Dictionary = transit.network.hub_of(to)
	assert_eq(world.layout.district_of(_absolute_cell(player.global_position)), to)
	assert_lt(player.global_position.distance_to(DoorPlaces.scene_position(world, target["cell"], target["floor"], target["unit"])), 3.0)
	assert_eq(jobs.courier.wallet.credits, 100 - TransitNetwork.fare(from, to))
	assert_eq(session.clock.total_minutes, minutes + Economy.whole("transit", "ride_minutes"))
	# With a pass the next ride is free.
	jobs.courier.tools["transit_pass"] = 1
	assert_true(transit.ride(to, from))
	assert_eq(jobs.courier.wallet.credits, 100 - TransitNetwork.fare(from, to))


func test_no_ride_without_the_fare() -> void:
	var from := world.layout.district_of(SpawnFinder.find_on_foot(world.layout).cell) + Vector3i(0, -1, 0)
	jobs.courier.wallet.credits = 0
	var before := player.global_position
	assert_false(transit.ride(from, from + Vector3i(1, 0, 0)))
	assert_eq(player.global_position, before)
	assert_string_contains(transit.last_message, "fare")


func test_taking_the_lift() -> void:
	var spawn := SpawnFinder.find_on_foot(world.layout)
	var tall: BlockInfo = null
	for i in 17 * 17 * 4:
		var dx := i % 17 - 8
		var dz := (i / 17) % 17 - 8
		var dy := -(i / 289)
		if true:
			var block := world.layout.block_at(spawn.cell + Vector3i(dx, dy, dz))
			if block != null and world.population.plan_of(block).floors >= BlockNav.LIFT_MIN_FLOORS:
				tall = block
				break
		if tall != null:
			break
	var plan := world.population.plan_of(tall)
	transit.open_lift(tall.cell, 0)
	var top := -1
	for i in transit.choices.size():
		if transit.choices[i]["floor"] == plan.floors - 1:
			top = i
	assert_gte(top, 0)
	panel.choose(top)
	var local := player.global_position - world.origin.scene_position_of_cell_center(tall.cell)
	assert_eq(_absolute_cell(player.global_position), tall.cell)
	assert_eq(plan.floor_at(local.y + 0.1), plan.floors - 1)
