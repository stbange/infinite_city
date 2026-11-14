extends GutTest
## Spec people-in-the-city on a small world.

const DAY := GameClock.MINUTES_PER_DAY

var world: CityWorld
var player: Player
var manager: InteriorManager
var interaction: Interaction
var session: GameSession
var people: PeopleManager


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
	people = PeopleManager.new()
	people.name = "PeopleManager"
	people.auto_update = false
	world.add_child(people)
	people.world_path = NodePath("..")
	people.session_path = NodePath("../GameSession")
	people.player_path = NodePath("../Player")
	people.interaction_path = NodePath("../Interaction")
	add_child_autofree(world)
	# Routines wait for the district's job market; build it now (the game builds it in the background).
	world.population.job_market(Vector3i(0, -3, 0))


## Puts the player's feet at a cell-local point (yaw 0 looks towards -z).
func _stand(cell: Vector3i, local: Vector3, yaw: float = 0.0) -> void:
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
	world.teleport_focus(absolute)
	player.set_view(yaw, 0.0)
	world.prime_focus()


## Stands in the corridor in front of a unit's door.
func _stand_at_door(cell: Vector3i, floor_index: int, unit_index: int) -> void:
	var plan := world.population.plan_of(world.layout.block_at(cell))
	var unit := plan.units[unit_index]
	_stand(cell, Vector3(unit.door_x, plan.floor_y(floor_index) + 0.02, unit.front_z() + unit.front_sign * 1.2))


func _settle(frames: int = 30) -> void:
	for i in frames:
		people.update()


func _local_of(agent: PersonAgent, cell: Vector3i) -> Vector3:
	return agent.global_position - world.origin.scene_position_of_cell_center(cell)


func _food_workplace_with_shift() -> Array:
	var market := world.population.job_market(Vector3i(0, -3, 0))
	var routines := Routines.new(world.population)
	var day := GameClock.new_game().day_number()
	for i in market.active_indices():
		var w := market.workplace(i)
		if not w.is_food:
			continue
		var staff := market.staff_of(w)
		for id in staff:
			var shift := routines.shift_of(id, day)
			if shift.x >= 0 and shift.y <= (day + 1) * DAY:
				return [w, (shift.x + shift.y) / 2]
	return []


func test_workers_behind_the_counter() -> void:
	var found := _food_workplace_with_shift()
	assert_false(found.is_empty())
	var w: WorkplaceInfo = found[0]
	session.clock.total_minutes = found[1]
	_stand_at_door(w.cell, w.floor_index, w.unit)
	_settle()
	var routines := Routines.new(world.population)
	var plan := world.population.plan_of(world.layout.block_at(w.cell))
	var unit := plan.units[w.unit]
	var on_shift := 0
	for id in world.population.job_market(w.id.district).staff_of(w):
		var step := routines.at(id, session.clock.total_minutes)
		if step.activity != "working":
			continue
		on_shift += 1
		var agent := people.agent_for(id.key())
		assert_not_null(agent, "figure for %s" % id.key())
		if agent == null:
			continue
		var local := _local_of(agent, w.cell)
		assert_true(unit.rect.grow(0.01).has_point(Vector2(local.x, local.z)), "inside the unit: %s" % local)
		assert_almost_eq(local.y, plan.floor_y(w.floor_index), 0.01)
	assert_gt(on_shift, 0)


func _home_block() -> BlockInfo:
	var spawn := SpawnFinder.find_on_foot(world.layout)
	for r in 6:
		for x in range(-r, r + 1):
			for z in range(-r, r + 1):
				var block := world.layout.block_at(spawn.cell + Vector3i(x, 0, z))
				if block != null and block.kind == BlockTypes.Kind.HOUSING and world.population.block_people(block).size() > 50:
					world.population.job_market(world.layout.district_of(block.cell))
					return block
	return null


func test_sleepers_out_of_sight() -> void:
	var block := _home_block()
	var people_here := world.population.block_people(block)
	var id: PersonId = people_here.ids[0]
	session.clock.total_minutes = (GameClock.new_game().day_number() + 1) * DAY + 3 * 60
	_stand_at_door(block.cell, id.floor_index(), id.unit_index())
	_settle(60)
	var sleeping := 0
	for i in people_here.size():
		var step := people.step_of(people_here.ids[i].key())
		if step != null and step.activity == "sleeping":
			sleeping += 1
			assert_null(people.agent_for(people_here.ids[i].key()))
	assert_gt(sleeping, 10)
	for agent in people.agents():
		assert_ne(people.step_of(agent.person_key).activity, "sleeping")


## Searches the morning for a shown commuter with a route; returns its key or "".
func _find_commuter(block: BlockInfo) -> String:
	var id: PersonId = world.population.block_people(block).ids[0]
	_stand_at_door(block.cell, id.floor_index(), id.unit_index())
	var start := GameClock.new_game().day_number() * DAY + 5 * 60 + 30
	for k in 40:
		session.clock.total_minutes = start + k * 5
		_settle(25)
		for agent in people.agents():
			var step := people.step_of(agent.person_key)
			var route := people.route_of(agent.person_key)
			if step.walking and route != null and not route.is_empty() and route.length > 10.0:
				var walked := (session.clock.exact_minutes() - step.start) / session.clock.speed * PeopleManager.WALK_SPEED
				if walked < route.length - 4.0:
					return agent.person_key
	return ""


func test_a_commuter_on_the_route() -> void:
	world.population.job_market(Vector3i(0, -3, 0))
	var block := _home_block()
	var key := _find_commuter(block)
	assert_ne(key, "")
	if key == "":
		return
	var step := people.step_of(key)
	var route := people.route_of(key)
	var base := world.origin.scene_position_of_cell_center(route.start_cell)
	var walked := (session.clock.exact_minutes() - step.start) / session.clock.speed * PeopleManager.WALK_SPEED
	assert_almost_eq(people.agent_for(key).global_position, base + route.point_at(walked), Vector3.ONE * 0.05)
	session.clock.advance_real(1.0)
	people.update()
	var later := walked + PeopleManager.WALK_SPEED
	assert_almost_eq(people.agent_for(key).global_position, base + route.point_at(later), Vector3.ONE * 0.05)
	assert_ne(people.agent_for(key).walk_phase, 0.0, "a walker swings their legs")


func test_figure_cap() -> void:
	world.population.job_market(Vector3i(0, -3, 0))
	var block := _home_block()
	var id: PersonId = world.population.block_people(block).ids[0]
	session.clock.total_minutes = GameClock.new_game().day_number() * DAY + 7 * 60 + 45
	_stand_at_door(block.cell, id.floor_index(), id.unit_index())
	_settle(60)
	assert_gt(people.agents().size(), 0)
	assert_lte(people.agents().size(), PeopleManager.MAX_AGENTS)
	for agent in people.agents():
		assert_lte(agent.global_position.distance_to(player.global_position), PeopleManager.VIEW_DISTANCE)
	_settle(200)
	var t0 := Time.get_ticks_usec()
	for i in 50:
		session.clock.advance_real(0.016)
		people.update()
	var per_frame := (Time.get_ticks_usec() - t0) / 50.0 / 1000.0
	gut.p("people update: %.2f ms per frame, %d figures, %d candidates" % [per_frame, people.agents().size(), people.candidate_count()])
	assert_lt(per_frame, 5.0, "steady-state update budget (2 ms target, margin for slow machines)")


func test_looking_at_a_person() -> void:
	var found := _food_workplace_with_shift()
	var w: WorkplaceInfo = found[0]
	session.clock.total_minutes = found[1]
	_stand_at_door(w.cell, w.floor_index, w.unit)
	_settle()
	var agent: PersonAgent = null
	for candidate in people.agents():
		if people.step_of(candidate.person_key).activity == "working":
			agent = candidate
			break
	assert_not_null(agent)
	var local := _local_of(agent, w.cell)
	_stand(w.cell, local + Vector3(0, 0, 1.5))
	people.update()
	interaction.refresh()
	var target := interaction.target()
	assert_eq(target.get("kind"), "person")
	var person := world.population.person(PersonId.from_key(agent.person_key))
	assert_string_contains(str(target.get("label")), person.given_name)
	assert_string_contains(str(target.get("label")), str(person.age))
	assert_string_contains(str(target.get("label")), "working")
