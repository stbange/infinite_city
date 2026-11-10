extends GutTest
## Spec relations: Family, Mutual relations, Neighbours and colleagues, Friends lovers and
## rivals, Enemies from history, Gossip, Fast relations.

var layout: CityLayout
var chronicle: CityChronicle
var population: Population
var relations: Relations


func before_all() -> void:
	var config := CityConfig.new()
	layout = CityLayout.new(config)
	chronicle = CityChronicle.new(config)
	population = Population.new(layout, chronicle)
	relations = Relations.new(population)


## Adults of housing blocks in a few districts (keeps job markets to a handful).
func _adults(count: int, salt: int) -> Array[PersonInfo]:
	var result: Array[PersonInfo] = []
	var rng := CellRandom.new(salt)
	var districts: Array[Vector3i] = [Vector3i(0, -3, 0), Vector3i(1, -3, 0)]
	while result.size() < count:
		var district := districts[rng.next_int(districts.size())]
		var cell := layout.district_origin_cell(district) + Vector3i(rng.next_int(8), rng.next_int(8), rng.next_int(8))
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		var flats := population.flats_of(block)
		var flat: Vector2i = flats[rng.next_int(flats.size())]
		for p in population.residents(cell, flat.x, flat.y):
			if p.age >= 18:
				result.append(p)
	return result


func _kinds_to(id: PersonId, other: PersonId) -> Array[String]:
	var kinds: Array[String] = []
	for r in relations.relations_of(id):
		if r.other.equals(other):
			kinds.append(r.kind)
	return kinds


func test_households_hold_families() -> void:
	var checked := 0
	var rng := CellRandom.new(3)
	while checked < 300:
		var cell := layout.district_origin_cell(Vector3i(0, -3, 0)) + Vector3i(rng.next_int(8), rng.next_int(8), rng.next_int(8))
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		var flats := population.flats_of(block)
		var flat: Vector2i = flats[rng.next_int(flats.size())]
		var house := population.household(cell, flat.x, flat.y)
		if house.type != "couple" and house.type != "family":
			continue
		var people := population.residents(cell, flat.x, flat.y)
		var adults: Array[PersonInfo] = []
		for p in people:
			if p.age >= 18 and p.age < 68:
				adults.append(p)
		adults.sort_custom(func(a: PersonInfo, b: PersonInfo) -> bool: return a.age > b.age)
		if adults.size() >= 2:
			assert_has(_kinds_to(adults[0].id, adults[1].id), "partner")
			assert_has(_kinds_to(adults[1].id, adults[0].id), "partner")
		for child in people:
			if child.age < 18:
				for adult in adults:
					assert_has(_kinds_to(child.id, adult.id), "parent")
					assert_has(_kinds_to(adult.id, child.id), "child")
		checked += 1


func test_family_lines_across_flats() -> void:
	var checked := 0
	for p in _adults(1500, 4):
		for r in relations.relations_of(p.id):
			if r.kind not in ["relative_parent", "relative_child", "sibling"]:
				continue
			assert_eq(r.other.cell(layout), p.id.cell(layout), "relatives live in the same block")
			var other := population.person(r.other)
			assert_eq(other.family_name, p.family_name)
			assert_has(_kinds_to(r.other, p.id), Relation.mirror(r.kind))
			checked += 1
		if checked >= 300:
			break
	assert_gte(checked, 100)


func test_mutuality() -> void:
	for p in _adults(400, 5):
		for r in relations.relations_of(p.id):
			var back := false
			for b in relations.relations_of(r.other):
				if b.other.equals(p.id) and b.kind == Relation.mirror(r.kind) and b.secret == r.secret:
					back = true
			assert_true(back, "%s → %s (%s) has no mirror" % [p.full_name(), r.other.key(), r.kind])


func test_who_is_next_door_and_at_work() -> void:
	var checked := 0
	for p in _adults(800, 6):
		var workplace := population.workplace_of(p.id)
		if workplace == null:
			continue
		var market := population.job_market(p.id.district)
		var staff := market.staff_of(market.workplace_at(workplace.id))
		var colleagues := 0
		for r in relations.relations_of(p.id):
			if r.kind == "colleague":
				colleagues += 1
				assert_true(staff.any(func(s: PersonId) -> bool: return s.equals(r.other)))
		if staff.size() - 1 <= Relations.MAX_COLLEAGUES:
			assert_eq(colleagues, staff.size() - 1)
		else:
			assert_between(colleagues, 1, staff.size() - 1)
		checked += 1
		if checked >= 200:
			break
	assert_gte(checked, 200)


func test_social_life_in_numbers() -> void:
	var adults := _adults(600, 7)
	var friends := 0
	var with_friend := 0
	var with_lover := 0
	for p in adults:
		var f := 0
		var lover := false
		for r in relations.relations_of(p.id):
			if r.kind == "friend":
				f += 1
			if r.kind == "lover":
				lover = true
				assert_true(r.secret)
		friends += f
		if f > 0:
			with_friend += 1
		if lover:
			with_lover += 1
	var n := float(adults.size())
	assert_between(friends / n, 2.0, 6.0)
	assert_gte(with_friend / n, 0.8)
	assert_between(with_lover / n, 0.02, 0.12)


func test_feuds_become_personal() -> void:
	var enemies := 0
	for p in _adults(2000, 8):
		for r in relations.relations_of(p.id):
			if r.kind != "enemy":
				continue
			enemies += 1
			var other := population.person(r.other)
			assert_false(p.membership.is_empty())
			assert_false(other.membership.is_empty())
			assert_true(relations.factions_feuded(p.membership, other.membership))
	assert_gt(enemies, 0)


func test_gossip_lines() -> void:
	var gossip := Gossip.new(population, relations)
	for p in _adults(300, 9):
		var lines := gossip.about(p.id)
		assert_between(lines.size(), 1, 3)
		for line in lines:
			assert_false(line.is_empty())
			assert_false(line.contains("?"), line)
		assert_eq(gossip.about(p.id), lines)


func test_relations_budget() -> void:
	var adults := _adults(1, 10)
	var block := layout.block_at(adults[0].id.cell(layout))
	var people := population.block_people(block)
	relations.relations_of(adults[0].id)
	var start := Time.get_ticks_usec()
	var n := 0
	for i in people.ids.size():
		if people.ages[i] >= 18:
			relations.relations_of(people.ids[i])
			n += 1
		if n >= 100:
			break
	var per := (Time.get_ticks_usec() - start) / 1000.0 / maxi(n, 1)
	assert_lt(per, 3.0, "%.2f ms per person (budget 2 ms, 50%% headroom)" % per)
