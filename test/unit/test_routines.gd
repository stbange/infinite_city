extends GutTest
## Spec routines: Day plans, Shifts, Evenings and nights.

const DAY := GameClock.MINUTES_PER_DAY

var layout: CityLayout
var population: Population
var routines: Routines
var residents: Array[PersonId] = []
var employed: Array[PersonId] = []
var first_day: int


func before_all() -> void:
	var config := CityConfig.new()
	layout = CityLayout.new(config)
	population = Population.new(layout, null)
	routines = Routines.new(population)
	first_day = GameClock.new_game().day_number()
	var spawn := SpawnFinder.find_on_foot(layout)
	var district := layout.district_of(spawn.cell)
	var market := population.job_market(district)
	var all := market.employees()
	for i in 200:
		employed.append(all[(i * 7919) % all.size()])
	# Residents of housing blocks around the spawn (same district).
	var r := 0
	while residents.size() < 300 and r < 8:
		for x in range(-r, r + 1):
			for z in range(-r, r + 1):
				if maxi(absi(x), absi(z)) != r:
					continue
				var cell := spawn.cell + Vector3i(x, 0, z)
				var block := layout.block_at(cell)
				if block == null or block.kind != BlockTypes.Kind.HOUSING or layout.district_of(cell) != district:
					continue
				var people := population.block_people(block)
				for i in range(0, people.size(), 5):
					residents.append(people.ids[i])
		r += 1


func after_all() -> void:
	routines = null
	population = null
	layout = null


func test_continuous_plans() -> void:
	assert_gte(residents.size(), 300)
	for id: PersonId in residents.slice(0, 300):
		var previous_end := -1
		for d in range(first_day, first_day + 7):
			var plan := routines.day_plan(id, d)
			assert_gt(plan.size(), 0)
			if previous_end >= 0 and plan[0].start != previous_end:
				fail_test("%s: day %d starts at %d, previous ended %d" % [id.key(), d, plan[0].start, previous_end])
				return
			for i in plan.size():
				var step := plan[i]
				if step.end <= step.start or (i > 0 and plan[i - 1].end != step.start):
					fail_test("%s: gap or overlap at %s" % [id.key(), step])
					return
				if step.walking:
					var before := plan[i - 1] if i > 0 else null
					var after := plan[i + 1] if i + 1 < plan.size() else null
					if (before != null and not before.place.equals(step.from)) or (after != null and not after.place.equals(step.place)):
						fail_test("%s: walk %s does not join its neighbours" % [id.key(), step])
						return
			previous_end = plan[plan.size() - 1].end
	pass_test("plans continuous")


func test_deterministic_routines() -> void:
	var config := CityConfig.new()
	var other := Routines.new(Population.new(CityLayout.new(config), null))
	for i in 20:
		var id := employed[i * 9]
		var minute := first_day * DAY + i * 97
		assert_true(routines.at(id, minute).equals(other.at(id, minute)))


func test_workers_at_work_during_their_shift() -> void:
	var checked := 0
	for id in employed:
		var day := first_day
		var shift := routines.shift_of(id, day)
		while shift.x < 0:
			day += 1
			shift = routines.shift_of(id, day)
		var mid := (shift.x + shift.y) / 2
		var step := routines.at(id, mid)
		var w := population.workplace_of(id)
		assert_eq(step.activity, "working")
		assert_true(step.place.equals(NavPlace.inside(w.cell, w.floor_index, w.unit)))
		assert_true(w.is_open_at(posmod(mid, DAY)) or w.is_open_at(posmod(mid, DAY) + DAY), "%s open at %d" % [w.name, posmod(mid, DAY)])
		checked += 1
	assert_eq(checked, 200)


func test_two_days_off() -> void:
	for id: PersonId in employed.slice(0, 50):
		var worked := 0
		for d in range(first_day, first_day + 7):
			if routines.shift_of(id, d).x >= 0:
				worked += 1
		assert_eq(worked, 5)


func test_home_at_night() -> void:
	var night_workers := 0
	for id: PersonId in residents.slice(0, 300):
		var minute := (first_day + 1) * DAY + 3 * 60
		var step := routines.at(id, minute)
		var shift := routines.shift_of(id, first_day)
		if shift.x >= 0 and shift.y > (first_day + 1) * DAY:
			night_workers += 1
			continue
		assert_eq(step.activity, "sleeping", id.key())
		assert_true(step.place.equals(routines.home_of(id)))


func test_evenings_out() -> void:
	var outings := 0
	for id: PersonId in residents.slice(0, 300):
		for d in range(first_day, first_day + 7):
			var plan := routines.day_plan(id, d)
			for i in plan.size():
				var step := plan[i]
				if step.activity != "out":
					continue
				outings += 1
				var venue := population.workplace(step.place.cell, step.place.floor_index, step.place.unit)
				assert_true(venue != null and venue.is_food)
				var d_cell := step.place.cell - routines.home_of(id).cell
				assert_lte(maxi(absi(d_cell.x), maxi(absi(d_cell.y), absi(d_cell.z))), Routines.VENUE_RANGE)
				assert_true(venue.is_open_at(posmod(step.start, DAY)) and venue.is_open_at(posmod(step.end - 1, DAY)))
				assert_eq(plan[i + 1].activity, "going home")
				assert_true(plan[i + 1].place.equals(routines.home_of(id)))
	assert_gt(outings, 50)
