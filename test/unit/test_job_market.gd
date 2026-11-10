extends GutTest
## Spec workplaces: Workplaces and job slots, Job market, Job market budget.

const DISTRICTS: Array[Vector3i] = [Vector3i(0, -3, 0), Vector3i(-4, -9, 6), Vector3i(7, -2, -5)]

var layout: CityLayout
var chronicle: CityChronicle
var population: Population
var markets: Array[JobMarket] = []


func before_all() -> void:
	var config := CityConfig.new()
	layout = CityLayout.new(config)
	chronicle = CityChronicle.new(config)
	population = Population.new(layout, chronicle)
	for district in DISTRICTS:
		markets.append(population.job_market(district))


func test_slots_cover_the_workforce() -> void:
	for market in markets:
		var slots := 0
		for i in market.workplace_count():
			assert_gte(market.slots_of(i), 0)
			slots += market.slots_of(i)
		for i in range(0, market.workplace_count(), maxi(1, market.workplace_count() / 150)):
			var workplace := market.workplace(i)
			assert_false(workplace.name.is_empty())
			assert_lt(workplace.opens, workplace.closes)
			assert_eq(workplace.slots, market.slots_of(i))
		assert_eq(slots, market.total_slots)
		assert_gt(market.working_age, 1000)
		assert_between(float(slots) / market.working_age, 0.85, 1.0)


func test_both_directions_agree() -> void:
	var market := markets[0]
	var counted := 0
	for i in market.active_indices():
		var workplace := market.workplace(i)
		var staff := market.staff_of(workplace)
		assert_lte(staff.size(), workplace.slots)
		for id in staff:
			assert_eq(market.workplace_of(id), workplace)
			counted += 1
	assert_eq(counted, market.employed)
	var checked := 0
	for id in market.employees():
		var workplace := market.workplace_of(id)
		assert_has(market.staff_of(workplace).map(func(p: PersonId) -> String: return p.key()), id.key())
		checked += 1
		if checked > 300:
			break


func test_employment() -> void:
	for market in markets:
		assert_between(float(market.employed) / market.working_age, 0.70, 0.95)
	var market := markets[0]
	var checked := 0
	for id in market.employees():
		var person := population.person(id)
		assert_between(person.age, 18, 67)
		checked += 1
		if checked > 500:
			break


func test_same_market_every_time() -> void:
	var other := Population.new(CityLayout.new(CityConfig.new()), CityChronicle.new(CityConfig.new()))
	var again := other.job_market(DISTRICTS[0])
	assert_eq(again.employed, markets[0].employed)
	var checked := 0
	for id in markets[0].employees():
		assert_eq(again.workplace_of(id).key(), markets[0].workplace_of(id).key())
		checked += 1
		if checked > 1000:
			break


func test_build_time() -> void:
	var fresh := Population.new(layout, chronicle)
	var start := Time.get_ticks_usec()
	fresh.job_market(Vector3i(3, -5, 3))
	var seconds := (Time.get_ticks_usec() - start) / 1000000.0
	assert_lt(seconds, 2.25, "job market took %.2f s (budget 1.5 s, 50%% headroom for slow machines)" % seconds)


## GUT keeps finished test scripts alive; release the big generators.
func after_all() -> void:
	layout = null
	chronicle = null
	population = null
	markets.clear()
