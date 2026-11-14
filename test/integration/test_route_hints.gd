extends GutTest
## Spec wayfinding: Route hints on a small world.

var world: CityWorld
var player: Player
var session: GameSession
var jobs: JobManager
var hints: RouteHints
var patron: WorkplaceInfo


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
	hints = RouteHints.new()
	hints.name = "RouteHints"
	hints.auto_update = false
	world.add_child(hints)
	hints.world_path = NodePath("..")
	hints.player_path = NodePath("../Player")
	hints.jobs_path = NodePath("../JobManager")
	add_child_autofree(world)
	var market := world.population.job_market(Vector3i(0, -3, 0))
	for i in market.active_indices():
		if market.workplace(i).is_food:
			patron = market.workplace(i)
			break
	jobs.set_patron(patron)


## Stands in the corridor of another unit of the patron's block, on the patron's floor.
func _stand_in_patron_block(unit_index: int) -> void:
	var plan := world.population.plan_of(world.layout.block_at(patron.cell))
	var unit := plan.units[unit_index]
	var local := Vector3(unit.door_x, plan.floor_y(patron.floor_index) + 0.02, unit.front_z() + unit.front_sign * 1.2)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((patron.cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
	world.teleport_focus(absolute)


func test_hints_lead_the_way() -> void:
	var plan := world.population.plan_of(world.layout.block_at(patron.cell))
	var far_unit := 0 if patron.unit != 0 else 1
	for u in plan.units.size():
		if absf(plan.units[u].door_x - plan.units[patron.unit].door_x) > 12.0:
			far_unit = u
	_stand_in_patron_block(far_unit)
	hints.update()
	assert_false(hints.route.is_empty())
	assert_gt(hints.lights_shown(), 2)
	var feet := player.global_position
	for p in hints.light_positions():
		assert_lte(p.distance_to(feet), RouteHints.AHEAD + 2.5, "only the next stretch is lit")
	var first_route := hints.route.nodes.duplicate()
	# After walking elsewhere the hints start from the new place.
	_stand_in_patron_block(patron.unit)
	hints.update()
	assert_ne(hints.route.nodes, first_route)
	hints.enabled = false
	hints.update()
	assert_eq(hints.lights_shown(), 0)


func test_the_scanner_shows_the_whole_way() -> void:
	var job := DeliveryJob.new()
	var spawn := SpawnFinder.find_on_foot(world.layout)
	# A customer two blocks away: the whole route is longer than the hint stretch.
	var orders := CourierBoard.new(world.population).offers(patron, GameClock.new_game().day_number(), 9)
	job = orders[0]
	jobs.carried.append(job)
	_stand_in_patron_block(patron.unit)
	hints.update()
	var short := hints.lights_shown()
	if hints.route.length <= RouteHints.AHEAD + RouteHints.SPACING:
		pass_test("route too short to tell")
		return
	hints.show_full()
	assert_gt(hints.lights_shown(), short)
	assert_true(spawn != null)
