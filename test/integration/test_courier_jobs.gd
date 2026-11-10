extends GutTest
## Specs addresses (Floor signs) and courier-jobs (Accepting and delivering, Waypoint, Saved
## courier state) on a small world.

var world: CityWorld
var player: Player
var manager: InteriorManager
var interaction: Interaction
var session: GameSession
var jobs: JobManager
var hud: Hud


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
	jobs.interaction_path = NodePath("../Interaction")
	add_child_autofree(world)
	hud = Hud.new()
	add_child_autofree(hud)
	hud.world_path = hud.get_path_to(world)
	hud.camera_path = hud.get_path_to(player)
	hud.interaction_path = hud.get_path_to(interaction)
	hud.jobs_path = hud.get_path_to(jobs)


func _patron() -> WorkplaceInfo:
	var market := world.population.job_market(Vector3i(0, -3, 0))
	for i in market.active_indices():
		var w := market.workplace(i)
		if w.is_food:
			return w
	return null


## Stands 1.5 m in front of a unit's door, facing it, with the block entered.
func _face(cell: Vector3i, floor_index: int, unit_index: int) -> void:
	var plan := world.population.plan_of(world.layout.block_at(cell))
	var unit := plan.units[unit_index]
	var local := Vector3(unit.door_x, plan.floor_y(floor_index) + 0.02, unit.front_z() + unit.front_sign * 1.5)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
	world.teleport_focus(absolute)
	player.set_view(0.0 if unit.front_sign > 0 else PI, 0.0)
	world.prime_focus()
	for i in 40:
		manager.update()
	interaction.refresh()


func test_a_delivery_from_counter_to_door() -> void:
	var patron := _patron()
	assert_not_null(patron)
	jobs.set_patron(patron)
	_face(patron.cell, patron.floor_index, patron.unit)
	assert_string_contains(str(interaction.target().get("label")), "Jobs at " + patron.name)
	var before := jobs.wallet.credits
	interaction.interact()
	assert_eq(jobs.carried.size(), 1)
	var job := jobs.carried[0]
	_face(job.dropoff_cell, job.dropoff_floor, job.dropoff_unit)
	assert_string_contains(str(interaction.target().get("label")), "Deliver to " + job.customer_name)
	var pay := CourierBoard.pay_for(job, session.clock.total_minutes)
	interaction.interact()
	assert_eq(jobs.carried.size(), 0)
	assert_eq(jobs.completed, 1)
	assert_eq(jobs.wallet.credits, before + pay)


func test_waypoint_read_out() -> void:
	var patron := _patron()
	jobs.set_patron(patron)
	_face(patron.cell, patron.floor_index, patron.unit)
	interaction.interact()
	var job := jobs.carried[0]
	hud.refresh()
	assert_string_contains(hud.text(), job.customer_name)
	assert_string_contains(hud.text(), " m")
	assert_string_contains(hud.text(), "¤")
	var waypoint := jobs.waypoint()
	assert_false(waypoint.is_empty())


func test_floor_numbers_at_the_stairs() -> void:
	var patron := _patron()
	var floor_index := 3 if world.population.plan_of(world.layout.block_at(patron.cell)).floors > 4 else 1
	_face(patron.cell, floor_index, patron.unit)
	var view := manager.view_for(patron.cell)
	var k := view.floor_index_at(player.global_position)
	var texts := view.plate_texts()
	for f in range(maxi(0, k - 1), mini(view.plan.floors, k + 2)):
		assert_has(texts, "Fl %d" % (f + 1))


func test_courier_state_survives_a_reload() -> void:
	var patron := _patron()
	jobs.set_patron(patron)
	_face(patron.cell, patron.floor_index, patron.unit)
	interaction.interact()
	jobs.wallet.credits = 333
	var saved := JSON.parse_string(JSON.stringify(session.to_dict())) as Dictionary
	jobs.wallet.credits = 0
	jobs.carried.clear()
	assert_eq(session.from_dict(saved), "")
	assert_eq(jobs.wallet.credits, 333)
	assert_eq(jobs.carried.size(), 1)
	assert_eq(jobs.carried[0].customer_name, (saved["courier"]["carried"] as Array)[0]["customer_name"])
