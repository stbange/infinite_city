extends GutTest
## Specs checkpoints, blackouts, escorts and rival-couriers: the rules.


func _job(kind: String) -> DeliveryJob:
	var job := DeliveryJob.new()
	job.cargo_kind = kind
	return job


func test_checkpoints_near_the_roof() -> void:
	var layout := SharedCity.layout()
	var roof := layout.config.roof_layer
	var spawn := SpawnFinder.find_on_foot(layout)
	var near := 0
	var deep := 0
	for x in range(-12, 13):
		for z in range(-12, 13):
			for dy: int in [0, -1, -5]:
				var cell := Vector3i(spawn.cell.x + x, roof + dy, spawn.cell.z + z)
				for bridge in layout.bridges_of(cell):
					if EncounterRules.is_checkpoint(layout.config.world_seed, bridge, roof):
						if roof - bridge.cell_a.y < Economy.whole("checkpoints", "layers"):
							near += 1
						else:
							deep += 1
	assert_gt(near, 0, "some bridges at the fogline have checkpoints")
	assert_eq(deep, 0, "none deeper down")


func test_what_a_checkpoint_wants() -> void:
	var none: Array[DeliveryJob] = []
	assert_eq(EncounterRules.checkpoint(none, false)["kind"], "pass")
	var food: Array[DeliveryJob] = [_job("food")]
	assert_eq(EncounterRules.checkpoint(food, false)["kind"], "permit")
	assert_eq(EncounterRules.checkpoint(food, true)["kind"], "pass", "light rights")
	var smuggled: Array[DeliveryJob] = [_job("food"), _job("contraband")]
	var check := EncounterRules.checkpoint(smuggled, true)
	assert_eq(check["kind"], "contraband", "light rights do not hide contraband")
	assert_gt(check["price"], EncounterRules.toll(2, 0.0))


func test_light_rights() -> void:
	var courier := CourierState.new()
	courier.wallet.credits = 5000
	assert_false(courier.buy_light_rights(), "bronze is not enough")
	courier.licence = "silver"
	assert_true(courier.buy_light_rights())
	assert_eq(courier.wallet.credits, 5000 - Economy.whole("licences", "light_rights_fee"))
	var copy := CourierState.new()
	copy.from_dict(courier.to_dict())
	assert_true(copy.light_rights)


func test_blackout_nights() -> void:
	var overlays := WorldOverlays.new()
	var district := Vector3i(1, -2, 3)
	var day := 1000
	overlays.apply({"kind": "blackout", "district": WorldOverlays.district_key(district), "day": day})
	var at := func(h: int, d: int = day) -> int: return d * GameClock.MINUTES_PER_DAY + h * 60
	assert_false(overlays.is_dark(district, at.call(18)))
	assert_true(overlays.is_dark(district, at.call(22)))
	assert_true(overlays.is_dark(district, at.call(3, day + 1)))
	assert_false(overlays.is_dark(district, at.call(7, day + 1)))
	assert_false(overlays.is_dark(district + Vector3i(1, 0, 0), at.call(22)))


func test_blackouts_in_the_live_area() -> void:
	var population := SharedCity.population()
	var district := population.layout.district_of(SpawnFinder.find_on_foot(population.layout).cell)
	var overlays := WorldOverlays.new()
	var turf := TurfMap.new(SharedCity.chronicle(), population.layout)
	var found := 0
	var districts: Array[Vector3i] = [district]
	for d in 60:
		for event in LiveSimulation.tick(population, SharedCity.chronicle(), overlays, turf, 200000 + d, districts, false, {}):
			overlays.apply(event)
			found += 1 if event["kind"] == "blackout" else 0
	assert_between(found, 1, 15, "now and then a district goes dark")


func test_escorts_at_gold() -> void:
	assert_eq(CargoKind.tier("person"), 4)
	assert_eq(Licence.max_tier("gold"), 4)
	var population := SharedCity.population()
	var board := CourierBoard.new(population)
	var market := population.job_market(Vector3i(0, -3, 0))
	var patron: WorkplaceInfo = null
	for i in market.active_indices():
		if market.workplace(i).is_food:
			patron = market.workplace(i)
			break
	var people := 0
	for hour in 24 * 4:
		for job in board.offers(patron, 600000 + hour / 24, hour % 24, 4):
			people += 1 if job.cargo_kind == "person" else 0
	assert_gt(people, 0, "a gold courier is offered escorts")


func test_rivals_take_orders() -> void:
	var population := SharedCity.population()
	var board := CourierBoard.new(population)
	var market := population.job_market(Vector3i(0, -3, 0))
	var patron := market.workplace(market.active_indices()[0])
	var taken := 0
	var total := 0
	for hour in 48:
		for i in CourierBoard.PER_HOUR:
			var m := board.rival_minute(patron, 600000, hour % 24, i)
			assert_eq(board.rival_minute(patron, 600000, hour % 24, i), m)
			total += 1
			if m >= 0:
				taken += 1
				assert_between(m, 10, 59)
	assert_between(float(taken) / total, 0.3, 0.7)
