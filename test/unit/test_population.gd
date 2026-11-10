extends GutTest
## Spec residents: Households fit their flats, Same residents every time, Names, Person
## attributes, Fast enough.

var layout: CityLayout
var chronicle: CityChronicle
var population: Population


func before_all() -> void:
	var config := CityConfig.new()
	layout = CityLayout.new(config)
	chronicle = CityChronicle.new(config)
	population = Population.new(layout, chronicle)


## [cell, floor, unit] of `count` flats spread over the city.
func _flats(count: int, salt: int) -> Array[Array]:
	var result: Array[Array] = []
	var rng := CellRandom.new(salt)
	while result.size() < count:
		var cell := Vector3i(rng.range_int(-120, 120), -rng.range_int(2, 60), rng.range_int(-120, 120))
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		var flats := population.flats_of(block)
		if flats.is_empty():
			continue
		var flat: Vector2i = flats[rng.next_int(flats.size())]
		result.append([cell, flat.x, flat.y])
	return result


func test_plausible_households() -> void:
	var vacant := 0
	var flats := _flats(2000, 1)
	for flat in flats:
		var household := population.household(flat[0], flat[1], flat[2])
		assert_between(household.ages.size(), 0, 6)
		if household.is_vacant():
			vacant += 1
			continue
		var oldest := 0
		for age in household.ages:
			oldest = maxi(oldest, age)
		assert_gte(oldest, 18, "household without an adult at %s" % [flat])
		for age in household.ages:
			if age < 18:
				assert_eq(household.type, "family")
				assert_gte(oldest - age, 16)
	assert_between(float(vacant) / flats.size(), 0.03, 0.15)


func _signature(people: Array[PersonInfo]) -> String:
	var parts := PackedStringArray()
	for p in people:
		parts.append("%s %d %s %s" % [p.full_name(), p.age, ",".join(p.traits), p.membership])
	return "|".join(parts)


func test_two_populations_agree() -> void:
	var flats := _flats(300, 2)
	var forward: Array[String] = []
	for flat in flats:
		forward.append(_signature(population.residents(flat[0], flat[1], flat[2])))
	var other := Population.new(CityLayout.new(CityConfig.new()), CityChronicle.new(CityConfig.new()))
	for i in range(flats.size() - 1, -1, -1):
		var flat := flats[i]
		assert_eq(_signature(other.residents(flat[0], flat[1], flat[2])), forward[i])


func test_shared_and_varied_names() -> void:
	var names := {}
	var people := 0
	for flat in _flats(1000, 3):
		var household := population.household(flat[0], flat[1], flat[2])
		var residents := population.residents(flat[0], flat[1], flat[2])
		if household.type == "couple" or household.type == "family":
			for p in residents:
				assert_eq(p.family_name, residents[0].family_name)
		for p in residents:
			names[p.full_name()] = true
			people += 1
	assert_gt(people, 1000)
	assert_gte(float(names.size()) / people, 0.6)


func test_attributes_in_range() -> void:
	var people := 0
	var adults := 0
	var members := 0
	var axes := population.trait_axes()
	for flat in _flats(1500, 4):
		for p in population.residents(flat[0], flat[1], flat[2]):
			people += 1
			assert_has(["she", "he", "they"], p.pronoun)
			assert_eq(p.traits.size(), 3)
			var used := {}
			for t in p.traits:
				var axis := population.axis_of_trait(t)
				assert_ne(axis, -1, t)
				assert_false(used.has(axis))
				used[axis] = true
			assert_between(p.wealth, 0.0, 1.0)
			assert_between(p.health, 0.0, 1.0)
			assert_false(p.skill.is_empty())
			if p.age >= 18:
				adults += 1
			if not p.membership.is_empty():
				members += 1
				var faction := chronicle.faction(p.membership)
				assert_not_null(faction)
				assert_true(faction.exists_at(CityHistory.PRESENT_YEAR))
				var reach := CityChronicle.reach_of(layout.district_of(p.id.cell(layout)))
				assert_eq(CityChronicle.reach_of_key(p.membership), reach)
				assert_eq(p.membership_secret, faction.type == "gang" or faction.type == "society")
		if people >= 3000:
			break
	assert_gte(people, 3000)
	assert_between(float(members) / adults, 0.10, 0.35)


func test_households_of_a_block() -> void:
	var blocks: Array[BlockInfo] = []
	var rng := CellRandom.new(5)
	while blocks.size() < 20:
		var block := layout.block_at(Vector3i(rng.range_int(-300, 300), -rng.range_int(2, 60), rng.range_int(-300, 300)))
		if block != null and block.kind == BlockTypes.Kind.HOUSING:
			blocks.append(block)
	var fresh := Population.new(layout, chronicle)
	var start := Time.get_ticks_usec()
	for block in blocks:
		var plan := fresh.plan_of(block)
		var culture := fresh.culture_of(layout.district_of(block.cell))
		for flat in fresh.flats_of(block):
			fresh.household_in(block, plan, flat.x, flat.y, culture)
	var per_block := (Time.get_ticks_usec() - start) / 1000.0 / blocks.size()
	assert_lt(per_block, 5.0, "%.2f ms per block" % per_block)


func test_person_ids_round_trip() -> void:
	var id := PersonId.of(layout, Vector3i(-13, -20, 7), 11, 23, 4)
	assert_eq(id.cell(layout), Vector3i(-13, -20, 7))
	assert_eq(id.floor_index(), 11)
	assert_eq(id.unit_index(), 23)
	assert_eq(id.slot(), 4)
	assert_true(id.equals(PersonId.from_key(id.key())))
