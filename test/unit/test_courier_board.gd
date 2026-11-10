extends GutTest
## Spec courier-jobs: Start scenario, Food orders, Pay and tips, Rent.

var layout: CityLayout
var population: Population
var board: CourierBoard
var start: Dictionary


func before_all() -> void:
	var config := CityConfig.new()
	layout = CityLayout.new(config)
	population = Population.new(layout, CityChronicle.new(config))
	board = CourierBoard.new(population)
	var spawn := SpawnFinder.find_on_foot(layout)
	start = StartScenario.find(population, spawn.cell)


func test_patron_and_home_near_the_start() -> void:
	var spawn := SpawnFinder.find_on_foot(layout)
	assert_false(start.is_empty())
	var patron: WorkplaceInfo = start["patron"]
	assert_true(patron.is_food)
	assert_gt(patron.slots, 0)
	var d := patron.cell - spawn.cell
	assert_lte(maxi(absi(d.x), absi(d.z)), 3)
	assert_lte(absi(d.y), 2)
	var home_cell: Vector3i = start["home_cell"]
	assert_true(population.household(home_cell, start["home_floor"], start["home_unit"]).is_vacant())


func test_orders_near_the_counter() -> void:
	var patron: WorkplaceInfo = start["patron"]
	var day := 517 * 365
	for hour in 24:
		var orders := board.offers(patron, day, hour)
		assert_eq(orders.size(), 3)
		var again := board.offers(patron, day, hour)
		for i in orders.size():
			var job := orders[i]
			assert_eq(job.id, again[i].id)
			var d := job.dropoff_cell - patron.cell
			assert_lte(maxi(absi(d.x), absi(d.z)), 2)
			assert_lte(absi(d.y), 1)
			var customer := population.person(job.customer)
			assert_not_null(customer)
			assert_gte(customer.age, 18)
			assert_eq(job.customer.cell(layout), job.dropoff_cell)
			assert_eq(job.customer.floor_index(), job.dropoff_floor)
			assert_eq(job.customer.unit_index(), job.dropoff_unit)


func test_hot_food_pays_better() -> void:
	var job := board.offers(start["patron"], 517 * 365, 12)[0]
	job.picked_minute = 1000
	var hot := CourierBoard.pay_for(job, 1005)
	var cold := CourierBoard.pay_for(job, 1040)
	assert_gt(hot, cold)
	assert_eq(cold, job.base_pay)
	var expected := 12.0 + 0.15 * job.distance + 3.0 * job.floors
	assert_eq(job.base_pay, roundi(expected))


func test_monday_rent() -> void:
	var clock := GameClock.new()
	clock.total_minutes = 7 * GameClock.MINUTES_PER_DAY * 1000 - 60   # Sunday 23:00 before a Monday
	var wallet := Wallet.new()
	wallet.credits = 100
	wallet.start(clock)
	clock.add_minutes(6 * 60)   # Monday 05:00
	wallet.update(clock)
	assert_eq(wallet.credits, 100)
	clock.add_minutes(90)   # Monday 06:30
	wallet.update(clock)
	assert_eq(wallet.credits, -20)
	wallet.update(clock)
	assert_eq(wallet.credits, -20, "rent is charged once a week")
