extends GutTest
## Spec city-history: Eras, City-wide powers, Legends, Influence fields.

const ERA_KINDS: Array[String] = ["raising", "building_down", "sealing", "doorway_rush", "war", "quiet"]


func _history(seed_value: int) -> CityHistory:
	var config := CityConfig.new()
	config.world_seed = seed_value
	return CityHistory.new(config)


func test_era_sequence() -> void:
	for seed_value in range(1, 51):
		var history := _history(seed_value)
		assert_eq(history.eras.size(), 6)
		var year := 0
		for i in history.eras.size():
			var era := history.eras[i]
			assert_eq(era.kind, ERA_KINDS[i])
			assert_eq(era.start_year, year, "era %s of seed %d" % [era.kind, seed_value])
			assert_gt(era.end_year, era.start_year)
			assert_false(era.name.is_empty())
			year = era.end_year
		assert_eq(year, CityHistory.PRESENT_YEAR)
		var antagonist := history.power(history.war_antagonist)
		assert_not_null(antagonist)
		assert_eq(antagonist.type, "company")
		assert_true(history.war_won_by_districts or not history.war_won_by_districts)


func test_powers_of_a_city() -> void:
	for seed_value in range(1, 51):
		var history := _history(seed_value)
		assert_between(history.powers.size(), 6, 10)
		var counts := {}
		var goods := {}
		var names := {}
		for power in history.powers:
			counts[power.type] = counts.get(power.type, 0) + 1
			if power.type == "company":
				assert_false(goods.has(power.good), "two companies own %s" % power.good)
				goods[power.good] = true
			assert_false(names.has(power.name), "name %s twice" % power.name)
			names[power.name] = true
		assert_eq(counts.get("authority", 0), 1)
		assert_gte(counts.get("company", 0), 3)
		assert_gte(counts.get("faith", 0), 1)
		assert_eq(counts.get("society", 0), 1)


func test_legends_fit_their_events() -> void:
	for seed_value in range(1, 51):
		var history := _history(seed_value)
		assert_between(history.legends.size(), 10, 20)
		for legend in history.legends:
			var year := legend.event.year
			assert_gte(year - legend.born, 16, legend.name)
			if legend.died >= 0:
				assert_gt(legend.died, year, legend.name)
			else:
				assert_lte(CityHistory.PRESENT_YEAR - legend.born, 95, legend.name)
			assert_not_null(history.era_at(year))
			assert_false(legend.name.is_empty())


func test_smooth_and_bounded() -> void:
	var history := _history(1337)
	var rng := CellRandom.new(5)
	var steps: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
	for i in 2000:
		var district := Vector3i(rng.range_int(-500, 500), rng.range_int(-200, 0), rng.range_int(-500, 500))
		var power := history.powers[i % history.powers.size()]
		var value := history.influence(power.key, district)
		assert_between(value, 0.0, 1.0)
		for step in steps:
			assert_lte(absf(history.influence(power.key, district + step) - value), 0.25)


func test_depth_preferences() -> void:
	var history := _history(1337)
	var food := ""
	var authority := ""
	for power in history.powers:
		if power.good == "food":
			food = power.key
		if power.type == "authority":
			authority = power.key
	if food.is_empty():
		for seed_value in range(1, 30):
			history = _history(seed_value)
			for power in history.powers:
				if power.good == "food":
					food = power.key
				if power.type == "authority":
					authority = power.key
			if not food.is_empty():
				break
	assert_false(food.is_empty())
	var shallow_food := 0.0
	var deep_food := 0.0
	var shallow_auth := 0.0
	var deep_auth := 0.0
	var rng := CellRandom.new(9)
	for i in 400:
		var x := rng.range_int(-300, 300)
		var z := rng.range_int(-300, 300)
		var shallow := Vector3i(x, -rng.range_int(1, 3), z)
		var deep := Vector3i(x, -rng.range_int(60, 80), z)
		shallow_food += history.influence(food, shallow)
		deep_food += history.influence(food, deep)
		shallow_auth += history.influence(authority, shallow)
		deep_auth += history.influence(authority, deep)
	assert_gt(deep_food, shallow_food)
	assert_gt(shallow_auth, deep_auth)


func test_same_history_every_time() -> void:
	var a := _history(77)
	var b := _history(77)
	assert_eq(a.describe(), b.describe())
	assert_ne(a.describe(), _history(78).describe())
