extends GutTest
## Specs economy-tables (Economy table, Balance report, Session stats) and first-night-guide.


func after_each() -> void:
	Economy.clear_overrides()


func test_the_table_is_valid() -> void:
	var table := DataTables.load_table("economy")
	assert_eq(table.problems.size(), 0, str(table.problems))
	for section: String in Economy.SECTIONS:
		assert_true((table.data as Dictionary).has(section), section)


func test_rules_read_the_table() -> void:
	var before := EncounterRules.toll(1, 0.0)
	Economy.set_override("encounters", "toll_base", 100.0)
	assert_gt(EncounterRules.toll(1, 0.0), before)
	Economy.set_override("rent", "amount", 7)
	assert_eq(Wallet.RENT, 7)
	Economy.set_override("shop", "scanner", 1)
	assert_true(ShopCatalogue.can_buy("scanner", "bronze", 1, {}))
	Economy.set_override("pay", "base", 500.0)
	assert_gt(CourierBoard.BASE, 499.0)


func test_a_day_of_steady_play() -> void:
	var config := CityConfig.new()
	var population := Population.new(CityLayout.new(config), null)
	var start := StartScenario.find(population, SpawnFinder.find_on_foot(population.layout).cell)
	var sim := BalanceSim.new(population)
	var day := GameClock.new_game().day_number() * GameClock.MINUTES_PER_DAY
	var a := sim.play(start["patron"], day + 7 * 60, day + 15 * 60)
	var b := BalanceSim.new(Population.new(CityLayout.new(config), null)).play(start["patron"], day + 7 * 60, day + 15 * 60)
	assert_eq(a["earnings"], b["earnings"], "deterministic")
	assert_gt(a["deliveries"], 5)
	# Tuning target: a half day of steady play earns between a fifth and a half of the weekly rent.
	assert_between(float(a["earnings"]), Wallet.RENT * 0.2, Wallet.RENT * 0.5)
	assert_gt(a["tips"], 0, "food can still arrive hot")


func test_session_stats() -> void:
	var stats := PlayStats.new()
	stats.start(600)
	stats.order_taken()
	stats.delivered(20, 600, 630)
	stats.toll(10)
	stats.rescued()
	assert_almost_eq(stats.per_game_hour(stats.deliveries, 660), 1.0, 0.001)
	assert_almost_eq(stats.average_delivery_minutes(), 30.0, 0.001)
	assert_string_contains("\n".join(stats.lines(660)), "tolls ¤10")


func test_the_guide_steps_through_the_first_night() -> void:
	var guide := FirstNightGuide.new()
	assert_string_contains(guide.prompt("Ada's Noodles"), "Ada's Noodles")
	guide.mark("order_taken")
	assert_string_contains(guide.prompt(""), "deliver")
	guide.mark("delivered")
	guide.mark("scene_answered")
	assert_string_contains(guide.prompt(""), "U")
	guide.mark("shop_opened")
	assert_true(guide.is_finished())
	var copy := FirstNightGuide.new()
	copy.from_dict(guide.to_dict())
	assert_true(copy.is_finished())
