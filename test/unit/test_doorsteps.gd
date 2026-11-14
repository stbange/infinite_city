extends GutTest
## Spec doorsteps: Who answers the door.

const DAY := GameClock.MINUTES_PER_DAY

var population: Population
var routines: Routines
var people: Array[PersonId] = []
var first_day: int


func before_all() -> void:
	population = SharedCity.population()
	routines = Routines.new(population)
	first_day = GameClock.new_game().day_number()
	var spawn := SpawnFinder.find_on_foot(population.layout)
	population.job_market(population.layout.district_of(spawn.cell))
	for dx in range(-3, 4):
		for dz in range(-3, 4):
			var cell := spawn.cell + Vector3i(dx, 0, dz)
			var block := population.layout.block_at(cell)
			if block == null or block.kind != BlockTypes.Kind.HOUSING or population.layout.district_of(cell) != population.layout.district_of(spawn.cell):
				continue
			var bp := population.block_people(block)
			for i in range(0, bp.size(), 3):
				if bp.ages[i] >= 18:
					people.append(bp.ids[i])


func test_who_answers() -> void:
	var seen := {}
	for minute: int in [first_day * DAY + 3 * 60, first_day * DAY + 11 * 60, first_day * DAY + 20 * 60]:
		for id: PersonId in people.slice(0, 120):
			var result := DoorstepRules.answer(population, routines, id, minute)
			var step := routines.at(id, minute)
			seen[result["state"]] = true
			match str(result["state"]):
				"home":
					assert_eq(step.activity, "at home")
					assert_true((result["who"] as PersonId).equals(id))
				"asleep":
					assert_eq(step.activity, "sleeping")
				"household":
					assert_false((result["who"] as PersonId).equals(id))
					assert_eq(routines.at(result["who"], minute).activity, "at home")
				"left":
					assert_null(result["who"])
			assert_eq(float(result["tip"]), float(DoorstepRules.TIP_FACTORS[result["state"]]))
			assert_false(str(result["line"]).is_empty())
	for state: String in ["home", "asleep", "left"]:
		assert_true(seen.has(state), "someone is %s" % state)


func test_tips_follow_the_answer() -> void:
	var job := DeliveryJob.new()
	job.base_pay = 20
	job.picked_minute = 0
	assert_gt(CourierBoard.pay_for(job, 0, 1.0), CourierBoard.pay_for(job, 0, 0.3))
	assert_eq(CourierBoard.pay_for(job, 0, 0.0), job.base_pay)
