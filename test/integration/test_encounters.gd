extends GutTest
## Spec encounters on a small world: tolls, no cargo, escape, capture.

var world: CityWorld
var player: Player
var session: GameSession
var jobs: JobManager
var director: EncounterDirector


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
	director = EncounterDirector.new()
	director.name = "EncounterDirector"
	director.auto_update = false
	world.add_child(director)
	director.world_path = NodePath("..")
	director.session_path = NodePath("../GameSession")
	director.player_path = NodePath("../Player")
	director.jobs_path = NodePath("../JobManager")
	add_child_autofree(world)


## A claimed bridge near the start and a game hour whose roll with one order is `wanted`.
func _claimed_bridge(wanted: String) -> Array:
	var turf := TurfMap.new(world.chronicle, world.layout)
	var spawn := SpawnFinder.find_on_foot(world.layout)
	var first_hour := session.clock.total_minutes / 60
	for x in range(-10, 11):
		for z in range(-10, 11):
			for bridge in world.layout.bridges_of(spawn.cell + Vector3i(x, 0, z)):
				if turf.claim_of(bridge).is_empty() or EncounterRules.is_checkpoint(world.config.world_seed, bridge, world.config.roof_layer):
					continue
				for h in 48:
					if EncounterRules.roll(world.config.world_seed, bridge, first_hour + h, 1, 0.0) == wanted:
						return [bridge, first_hour + h]
	return []


func _stand_on(bridge: BridgeInfo, along: float) -> void:
	var local := bridge.start.lerp(bridge.end, along) + Vector3(0, 0.02, 0)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((bridge.cell_a[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
	world.teleport_focus(absolute)
	world.prime_focus()
	player.mode = Player.Mode.WALK


func _carry_one() -> void:
	var job := DeliveryJob.new()
	job.id = "test"
	jobs.carried.append(job)


func _offer(wanted: String = "toll") -> BridgeInfo:
	var found := _claimed_bridge(wanted)
	assert_false(found.is_empty(), "a claimed bridge with a %s" % wanted)
	var bridge: BridgeInfo = found[0]
	session.clock.total_minutes = found[1] * 60 + 5
	_carry_one()
	_stand_on(bridge, 0.3)
	director.update(0.016)
	return bridge


func test_a_toll_on_the_bridge() -> void:
	_offer("toll")
	assert_eq(director.state, EncounterDirector.State.OFFER)
	assert_eq(director.kind, "toll")
	assert_eq(director.price, EncounterRules.toll(1, 0.0))
	assert_string_contains(director.hud_line(), "1 pay")
	jobs.courier.wallet.credits = 100
	director.pay()
	assert_eq(jobs.courier.wallet.credits, 100 - EncounterRules.toll(1, 0.0))
	assert_eq(director.state, EncounterDirector.State.IDLE)
	assert_eq(jobs.carried.size(), 1)
	# Once per bridge and hour.
	director.update(0.016)
	assert_eq(director.state, EncounterDirector.State.IDLE)


func test_no_cargo_no_encounter() -> void:
	var found := _claimed_bridge("toll")
	var bridge: BridgeInfo = found[0]
	session.clock.total_minutes = found[1] * 60 + 5
	_stand_on(bridge, 0.3)
	director.update(0.016)
	assert_eq(director.state, EncounterDirector.State.IDLE)


func test_escaping_a_chase() -> void:
	var bridge := _offer("toll")
	assert_eq(director.state, EncounterDirector.State.OFFER)
	var gang := director.gang_key
	var before := director.heat.value_at(gang, session.clock.total_minutes)
	director.run()
	assert_eq(director.state, EncounterDirector.State.CHASE)
	# Off the bridge and far away along it, out of reach.
	var away := bridge.start - Vector3(0, 0, 0)
	away[bridge.axis] -= 60.0
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((bridge.cell_a[axis] + 0.5) * world.config.cell_size[axis] + away[axis])
	world.teleport_focus(absolute)
	director.update(0.016)
	assert_eq(director.state, EncounterDirector.State.IDLE)
	assert_eq(jobs.carried.size(), 1)
	assert_gt(director.heat.value_at(gang, session.clock.total_minutes), before)


func test_caught() -> void:
	_offer("toll")
	jobs.courier.wallet.credits = 100
	director.run()
	for i in 200:
		director.update(0.05)
		if director.state != EncounterDirector.State.CHASE:
			break
	assert_eq(director.state, EncounterDirector.State.IDLE)
	assert_eq(jobs.carried.size(), 0)
	assert_lt(jobs.courier.wallet.credits, 100)


func test_gangs_remember() -> void:
	var found := _claimed_bridge("toll")
	var bridge: BridgeInfo = found[0]
	session.clock.total_minutes = found[1] * 60 + 5
	_carry_one()
	_stand_on(bridge, 0.3)
	director.update(0.016)
	var gang := director.gang_key
	jobs.courier.wallet.credits = 100
	director.pay()
	var after_paying := jobs.courier.reputation.of(gang)
	assert_gt(after_paying, 0)
	# The next hour with a toll on the same bridge: run this time.
	for h in range(1, 200):
		if EncounterRules.roll(world.config.world_seed, bridge, found[1] + h, 1, director.heat.value_at(gang, (found[1] + h) * 60 + 5)) != "pass":
			session.clock.total_minutes = (found[1] + h) * 60 + 5
			break
	director.update(0.016)
	assert_eq(director.state, EncounterDirector.State.OFFER)
	director.run()
	assert_lt(jobs.courier.reputation.of(gang), after_paying)


func _tools() -> TraversalTools:
	var t := TraversalTools.new()
	t.name = "TraversalTools"
	world.add_child(t)
	t.player_path = NodePath("../Player")
	t.jobs_path = NodePath("../JobManager")
	t.encounters_path = NodePath("../EncounterDirector")
	return t


func test_a_flare_in_a_chase() -> void:
	var t := _tools()
	_offer("toll")
	director.run()
	assert_eq(director.state, EncounterDirector.State.CHASE)
	jobs.courier.tools["flare"] = 2
	assert_true(t.flare())
	assert_eq(director.state, EncounterDirector.State.IDLE)
	assert_eq(jobs.carried.size(), 1)
	assert_eq(jobs.courier.tools["flare"], 1)


func test_scanning_for_the_door() -> void:
	var t := _tools()
	var market := world.population.job_market(Vector3i(0, -3, 0))
	var patron: WorkplaceInfo = null
	for i in market.active_indices():
		if market.workplace(i).is_food:
			patron = market.workplace(i)
			break
	jobs.set_patron(patron)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((patron.cell[axis] + 0.5) * world.config.cell_size[axis])
	world.teleport_focus(absolute)
	assert_false(t.scan(), "no scanner yet")
	jobs.courier.tools["scanner"] = 1
	assert_true(t.scan())
	assert_true(t.beacon_visible())
	assert_almost_eq(t.beacon_position(), jobs.waypoint()["position"], Vector3.ONE * 0.01)


func test_chasers_follow_the_graph() -> void:
	var bridge := _offer("toll")
	director.run()
	# The courier runs into the block at the bridge's start and up a floor.
	var plan := world.population.plan_of(world.layout.block_at(bridge.cell_a))
	var unit := plan.units[0]
	var floor_index := mini(plan.floor_at(bridge.start.y + 0.5) + 1, plan.floors - 1)
	var local := Vector3(unit.door_x, plan.floor_y(floor_index) + 0.02, unit.front_z() + unit.front_sign * 1.2)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((bridge.cell_a[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
	world.teleport_focus(absolute)
	director.update(0.05)
	var routed := 0
	for path in director.chase_paths:
		if path.size() > 1:
			routed += 1
	assert_eq(routed, EncounterDirector.FIGURES, "every chaser has a path through the block")
	var before := director.chase_distance()
	for i in 10:
		director.update(0.1)
	if director.state == EncounterDirector.State.CHASE:
		assert_lt(director.chase_distance(), before, "they close in along the corridors and stairs")


func _checkpoint_bridge() -> BridgeInfo:
	var spawn := SpawnFinder.find_on_foot(world.layout)
	for x in range(-12, 13):
		for z in range(-12, 13):
			for dy: int in [0, -1]:
				var cell := Vector3i(spawn.cell.x + x, world.config.roof_layer + dy, spawn.cell.z + z)
				for bridge in world.layout.bridges_of(cell):
					if EncounterRules.is_checkpoint(world.config.world_seed, bridge, world.config.roof_layer):
						return bridge
	return null


func test_contraband_at_a_checkpoint() -> void:
	var bridge := _checkpoint_bridge()
	assert_not_null(bridge)
	_carry_one()
	var smuggled := DeliveryJob.new()
	smuggled.id = "crate"
	smuggled.cargo_kind = "contraband"
	jobs.carried.append(smuggled)
	_stand_on(bridge, 0.4)
	director.update(0.016)
	assert_eq(director.state, EncounterDirector.State.OFFER)
	assert_eq(director.kind, "contraband")
	assert_eq(director.gang_key, EncounterDirector.authority_key(world))
	assert_string_contains(director.hud_line(), "hand it over")
	director.run()
	assert_eq(director.state, EncounterDirector.State.IDLE, "no chase: they take it")
	assert_eq(jobs.carried.size(), 1)
	assert_eq(jobs.carried[0].cargo_kind, "food")


func test_permits_and_light_rights() -> void:
	var bridge := _checkpoint_bridge()
	_carry_one()
	jobs.courier.light_rights = true
	_stand_on(bridge, 0.4)
	director.update(0.016)
	assert_eq(director.state, EncounterDirector.State.IDLE, "light rights pass")
	session.clock.add_minutes(60)
	jobs.courier.light_rights = false
	director.update(0.016)
	assert_eq(director.kind, "permit")
	jobs.courier.wallet.credits = 100
	director.pay()
	assert_eq(jobs.courier.wallet.credits, 100 - Economy.whole("checkpoints", "permit"))


func test_an_escort_must_keep_up() -> void:
	var escort := Escort.new()
	escort.name = "Escort"
	escort.auto_update = false
	world.add_child(escort)
	escort.world_path = NodePath("..")
	escort.player_path = NodePath("../Player")
	escort.jobs_path = NodePath("../JobManager")
	escort.encounters_path = NodePath("../EncounterDirector")
	jobs.escort_path = NodePath("../Escort")
	var bridge := _claimed_bridge("toll")[0] as BridgeInfo
	var job := DeliveryJob.new()
	job.id = "witness"
	job.cargo_kind = "person"
	job.cargo = "a witness"
	var plan := world.population.plan_of(world.layout.block_at(bridge.cell_a))
	job.dropoff_cell = bridge.cell_a
	job.dropoff_floor = plan.floor_at(bridge.start.y + 0.5)
	job.dropoff_unit = 0
	job.customer = PersonId.of(world.layout, bridge.cell_a, job.dropoff_floor, 0, 0)
	job.pickup = job.customer
	jobs.carried.append(job)
	_stand_on(bridge, 0.5)
	escort.update(0.016)
	assert_not_null(escort.figure)
	# The courier dashes to the door while the escort is far behind.
	var door := DoorPlaces.scene_position(world, job.dropoff_cell, job.dropoff_floor, 0)
	escort.figure.global_position = door + Vector3(40, 0, 0)
	assert_false(escort.is_with(door))
	jobs._on_interacted({"kind": "door", "payload": {"cell": job.dropoff_cell, "floor": job.dropoff_floor, "unit": 0}})
	assert_eq(jobs.carried.size(), 1, "no delivery without the passenger")
	assert_string_contains(jobs.last_message, "passenger")
	# Waiting at the start, the escort walks up.
	var before := escort.figure.global_position.distance_to(player.global_position)
	for i in 30:
		escort.update(0.1)
	assert_lt(escort.figure.global_position.distance_to(player.global_position), maxf(before, Escort.KEEP_DISTANCE + 0.5))
