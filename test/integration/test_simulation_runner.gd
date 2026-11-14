extends GutTest
## Specs live-simulation (The changed world in play) and save-games (Saves keep the changed world).

const DAY := GameClock.MINUTES_PER_DAY


class Scene:
	var world: CityWorld
	var player: Player
	var session: GameSession
	var jobs: JobManager
	var runner: SimulationRunner


func _scene() -> Scene:
	var s := Scene.new()
	s.world = CityWorld.new()
	s.world.config = CityConfig.new()
	s.world.radius_h = 1
	s.world.radius_v = 1
	s.world.auto_tick = false
	s.player = Player.new()
	s.player.name = "Player"
	s.player.input_enabled = false
	s.player.start_mode = Player.Mode.FLY
	s.world.add_child(s.player)
	s.world.focus_path = NodePath("Player")
	s.session = GameSession.new()
	s.session.name = "GameSession"
	s.session.running = false
	s.world.add_child(s.session)
	s.session.world_path = NodePath("..")
	s.session.player_path = NodePath("../Player")
	s.jobs = JobManager.new()
	s.jobs.name = "JobManager"
	s.world.add_child(s.jobs)
	s.jobs.world_path = NodePath("..")
	s.jobs.session_path = NodePath("../GameSession")
	s.runner = SimulationRunner.new()
	s.runner.name = "SimulationRunner"
	s.runner.auto_update = false
	s.world.add_child(s.runner)
	s.runner.world_path = NodePath("..")
	s.runner.session_path = NodePath("../GameSession")
	s.runner.player_path = NodePath("../Player")
	s.runner.jobs_path = NodePath("../JobManager")
	add_child_autofree(s.world)
	var spawn := SpawnFinder.find_on_foot(s.world.layout)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((spawn.cell[axis] + 0.5) * s.world.config.cell_size[axis])
	s.world.teleport_focus(absolute)
	return s


func _cells(s: Scene) -> Array[Vector3i]:
	var spawn := SpawnFinder.find_on_foot(s.world.layout)
	var result: Array[Vector3i] = []
	for dx in range(-3, 4):
		for dz in range(-3, 4):
			result.append(spawn.cell + Vector3i(dx, 0, dz))
	return result


func _live_days(s: Scene, days: int) -> void:
	s.runner.update()
	for d in days:
		s.session.clock.add_minutes(DAY)
		s.runner.update()


func test_still_true_after_reloading() -> void:
	var a := _scene()
	_live_days(a, 6)
	assert_gt(a.runner.log.size(), 0)
	var saved := JSON.parse_string(JSON.stringify(a.session.to_dict())) as Dictionary
	var b := _scene()
	b.runner.update()
	assert_eq(b.session.from_dict(saved), "")
	assert_eq(b.runner.log.size(), a.runner.log.size())
	var turf_a := TurfMap.new(a.world.chronicle, a.world.layout)
	turf_a.overlays = a.runner.overlays
	var turf_b := TurfMap.new(b.world.chronicle, b.world.layout)
	turf_b.overlays = b.runner.overlays
	assert_eq(b.runner.overlays.state_hash(b.world.population, turf_b, _cells(b)),
			a.runner.overlays.state_hash(a.world.population, turf_a, _cells(a)))
	# Ticks once per day only.
	var count := b.runner.log.size()
	b.runner.update()
	assert_eq(b.runner.log.size(), count)


func test_version_2_with_events() -> void:
	var a := _scene()
	_live_days(a, 3)
	var saved := JSON.parse_string(JSON.stringify(a.session.to_dict())) as Dictionary
	assert_eq(int(saved["version"]), GameSession.SAVE_VERSION)
	assert_eq((saved["events"]["log"]["events"] as Array).size(), a.runner.log.size())


func test_older_saves_still_load() -> void:
	var a := _scene()
	_live_days(a, 3)
	var saved := JSON.parse_string(JSON.stringify(a.session.to_dict())) as Dictionary
	saved["version"] = 1
	saved.erase("events")
	var b := _scene()
	b.runner.update()
	assert_eq(b.session.from_dict(saved), "")
	assert_eq(b.runner.log.size(), 0)


func test_orders_follow_prices_and_the_dead() -> void:
	var a := _scene()
	a.runner.update()
	var market := a.world.population.job_market(Vector3i(0, -3, 0))
	var patron: WorkplaceInfo = null
	for i in market.active_indices():
		if market.workplace(i).is_food:
			patron = market.workplace(i)
			break
	a.jobs.set_patron(patron)
	var before := a.jobs.open_orders()
	assert_eq(before.size(), CourierBoard.PER_HOUR)
	var first := before[0]
	var district := a.world.layout.district_of(first.dropoff_cell)
	var event := a.runner.log.append("price", 0, {"district": WorldOverlays.district_key(district), "factor": 2.0})
	a.runner.overlays.apply(event)
	var dearer := a.jobs.open_orders()
	assert_eq(dearer[0].base_pay, roundi(first.base_pay * 2.0))
	event = a.runner.log.append("death", 0, {"person": first.customer.key()})
	a.runner.overlays.apply(event)
	for job in a.jobs.open_orders():
		assert_ne(job.customer.key(), first.customer.key())


func test_the_lights_go_out() -> void:
	var a := _scene()
	a.world.prime_focus()
	a.runner.update()
	var cell := a.world.origin.absolute_cell_of(a.player.global_position)
	var district := a.world.layout.district_of(cell)
	var day := a.session.clock.day_number()
	a.runner.record({"kind": "blackout", "district": WorldOverlays.district_key(district), "day": day}, a.session.clock.total_minutes)
	a.session.clock.total_minutes = day * DAY + 21 * 60
	a.runner.update()
	assert_true(a.runner.is_dark_at(a.world, cell))
	var dark := 0
	var lit := 0
	for chunk in a.world.loaded_chunks():
		var view := a.world.chunk_view(chunk)
		if view == null:
			continue
		for i in view.block_count():
			if view.block_custom(i).a > 0.5:
				dark += 1
			else:
				lit += 1
	assert_gt(dark, 0, "windows in the district are dark")
	a.session.clock.total_minutes = (day + 1) * DAY + 8 * 60
	a.runner.update()
	assert_false(a.runner.is_dark_at(a.world, cell))


func test_the_lamp_runs_on_a_battery() -> void:
	var a := _scene()
	var lamp := CourierLamp.new()
	lamp.name = "CourierLamp"
	a.world.add_child(lamp)
	lamp.player_path = NodePath("../Player")
	lamp.session_path = NodePath("../GameSession")
	lamp.jobs_path = NodePath("../JobManager")
	lamp.update()
	lamp.toggle()
	assert_true(lamp.on)
	a.session.clock.add_minutes(300)
	lamp.update()
	assert_almost_eq(lamp.battery, 0.5, 0.01)
	a.session.clock.add_minutes(400)
	lamp.update()
	assert_false(lamp.on)
	lamp.toggle()
	assert_false(lamp.on, "an empty lamp does not light")
	var market := a.world.population.job_market(Vector3i(0, -3, 0))
	a.jobs.set_patron(market.workplace(market.active_indices()[0]))
	var p := a.jobs.patron
	lamp._on_interacted({"kind": "door", "payload": {"cell": p.cell, "floor": p.floor_index, "unit": p.unit}})
	assert_eq(lamp.battery, 1.0)
