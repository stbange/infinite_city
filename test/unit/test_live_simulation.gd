extends GutTest
## Spec live-simulation: Daily ticks in the live area.

var layout: CityLayout
var population: Population
var chronicle: CityChronicle
var district: Vector3i
var first_day: int


func before_all() -> void:
	var config := CityConfig.new()
	layout = CityLayout.new(config)
	population = Population.new(layout, null)
	chronicle = CityChronicle.new(config)
	district = layout.district_of(SpawnFinder.find_on_foot(layout).cell)
	first_day = GameClock.new_game().day_number()


func after_all() -> void:
	population = null
	layout = null
	chronicle = null


## Ticks days in order, applying each day's events; returns [log, overlays].
func _run(days: int, shortage: bool, protected: Dictionary = {}, districts: Array[Vector3i] = []) -> Array:
	if districts.is_empty():
		districts = [district]
	var log := EventLog.new()
	var overlays := WorldOverlays.new()
	var turf := TurfMap.new(chronicle, layout)
	turf.overlays = overlays
	for d in days:
		for event in LiveSimulation.tick(population, chronicle, overlays, turf, first_day + d, districts, shortage, protected):
			log.events.append(event)
			overlays.apply(event)
	return [log, overlays]


func test_deterministic_ticks() -> void:
	var a: EventLog = _run(5, false)[0]
	var b: EventLog = _run(5, false)[0]
	assert_eq(JSON.stringify(a.to_dict()), JSON.stringify(b.to_dict()))


func test_a_week_in_the_district() -> void:
	var neighbours: Array[Vector3i] = [district, district + Vector3i(1, 0, 0), district + Vector3i(0, 0, 1), district + Vector3i(-1, 0, 0)]
	var result := _run(7, false, {}, neighbours)
	var log: EventLog = result[0]
	var kinds := {}
	for event in log.events:
		kinds[event["kind"]] = true
		match str(event["kind"]):
			"bridge_taken":
				assert_ne(event["gang"], event["from"])
				assert_eq(chronicle.faction(event["gang"]).type, "gang")
			"price":
				assert_between(float(event["factor"]), LiveSimulation.PRICE_MIN, LiveSimulation.PRICE_MAX)
	assert_true(kinds.has("bridge_taken"), "a bridge changed hands")
	assert_true(kinds.has("price"), "prices moved")


func test_prices_climb_with_the_shortage() -> void:
	var overlays: WorldOverlays = _run(4, true)[1]
	assert_gt(overlays.price_factor(district), 2.5)


func test_the_cast_is_safe() -> void:
	# Protect every resident the ticks touch in a first run, then run again.
	var first: EventLog = _run(40, false)[0]
	var protected := {}
	for event in first.events:
		if event.has("person"):
			protected[event["person"]] = true
	assert_gt(protected.size(), 0, "the ticks touch residents")
	var second: EventLog = _run(40, false, protected)[0]
	for event in second.events:
		if event.has("person"):
			assert_false(protected.has(event["person"]), "protected %s untouched" % event["person"])
