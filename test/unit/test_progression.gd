extends GutTest
## Spec courier-progression: Reputation, Licences and cargo tiers, Shop.


func test_levels_by_points() -> void:
	var expected := {-60: "hostile", -20: "wary", 0: "neutral", 30: "friendly", 80: "trusted"}
	for value: int in expected:
		assert_eq(Reputation.level_of(value), expected[value], str(value))
	var rep := Reputation.new()
	rep.add("x", 250)
	assert_eq(rep.of("x"), 100)


func test_upgrading_the_licence() -> void:
	var rep := Reputation.new()
	var fee := Licence.fee("bronze")
	assert_false(Licence.can_upgrade("bronze", rep, fee + 50))
	rep.add(Reputation.MUTUAL, Licence.REQUIREMENTS["silver"]["mutual"])
	assert_true(Licence.can_upgrade("bronze", rep, fee + 50))
	assert_false(Licence.can_upgrade("bronze", rep, fee - 1))
	assert_eq(Licence.next_level("bronze"), "silver")
	assert_false(Licence.can_upgrade("silver", rep, 100000))
	assert_eq(Licence.max_tier("bronze"), 1)
	assert_eq(Licence.max_tier("gold"), 4)


func test_higher_tiers_with_a_better_licence() -> void:
	var config := CityConfig.new()
	var population := Population.new(CityLayout.new(config), null)
	var board := CourierBoard.new(population)
	var market := population.job_market(Vector3i(0, -3, 0))
	var patron: WorkplaceInfo = null
	for i in market.active_indices():
		if market.workplace(i).is_food:
			patron = market.workplace(i)
			break
	var day := 517 * 365
	var tiers := {1: {}, 2: {}, 3: {}}
	for max_tier: int in [1, 2, 3]:
		for hour in 24:
			var orders := board.offers(patron, day, hour, max_tier)
			var plain := board.offers(patron, day, hour, 1)
			for i in orders.size():
				var job := orders[i]
				assert_lte(CargoKind.tier(job.cargo_kind), max_tier)
				(tiers[max_tier] as Dictionary)[CargoKind.tier(job.cargo_kind)] = true
				# Same trip, same customer; a higher tier pays more.
				assert_eq(job.customer.key(), plain[i].customer.key())
				if job.cargo_kind != "food":
					assert_gt(job.base_pay, plain[i].base_pay)
	assert_eq((tiers[1] as Dictionary).keys(), [1])
	assert_true((tiers[2] as Dictionary).has(2))
	assert_true((tiers[3] as Dictionary).has(3))


func test_buying_a_tool() -> void:
	var owned := {}
	var plenty := 100000
	assert_true(ShopCatalogue.can_buy("scanner", "bronze", ShopCatalogue.price("scanner"), owned))
	assert_false(ShopCatalogue.can_buy("scanner", "bronze", ShopCatalogue.price("scanner") - 1, {}))
	owned["scanner"] = 1
	assert_false(ShopCatalogue.can_buy("scanner", "bronze", plenty, owned))
	assert_false(ShopCatalogue.can_buy("glider", "bronze", plenty, owned))
	assert_true(ShopCatalogue.can_buy("glider", "silver", plenty, owned))
	assert_false(ShopCatalogue.can_buy("grapple", "silver", ShopCatalogue.price("grapple") - 1, owned))
	owned["flare"] = 2
	assert_true(ShopCatalogue.can_buy("flare", "bronze", ShopCatalogue.price("flare"), owned))
