extends GutTest
## Spec realistic-people: Looks.

var population: Population
var people: Array[PersonInfo] = []


func before_all() -> void:
	population = SharedCity.population()
	var spawn := SpawnFinder.find_on_foot(population.layout)
	for dx: int in range(-3, 4):
		for dz: int in range(-3, 4):
			var block := population.layout.block_at(spawn.cell + Vector3i(dx, 0, dz))
			if block == null or block.kind != BlockTypes.Kind.HOUSING:
				continue
			var bp := population.block_people(block)
			for i: int in range(0, bp.size(), 2):
				people.append(population.person(bp.ids[i]))


func _look(p: PersonInfo) -> FigureLook:
	return FigureLook.of(p, population.world_seed())


func test_looks_are_their_own() -> void:
	assert_gt(people.size(), 300)
	var a := _look(people[0])
	var b := _look(people[0])
	assert_eq(a.height, b.height)
	assert_eq(a.top, b.top)
	assert_eq(a.skin, b.skin)
	var distinct := {}
	for p: PersonInfo in people.slice(0, 100):
		var l := _look(p)
		distinct["%.2f|%s|%s" % [l.height, l.top.to_html(), l.skin.to_html()]] = true
	assert_gt(distinct.size(), 90, "people do not look alike")


func test_heights_by_age_and_pronoun() -> void:
	var sums := {"she": [0.0, 0], "he": [0.0, 0]}
	for p: PersonInfo in people:
		var l := _look(p)
		if p.age >= 18:
			assert_between(l.height, 1.45, 2.0, "adult %d" % p.age)
			if sums.has(p.pronoun):
				sums[p.pronoun][0] += l.height
				sums[p.pronoun][1] += 1
		else:
			assert_between(l.height, 0.75, 1.95, "child %d" % p.age)
		if p.age < 8:
			assert_lt(l.height, 1.4, "a young child is small")
	var she: float = sums["she"][0] / maxi(1, sums["she"][1])
	var he: float = sums["he"][0] / maxi(1, sums["he"][1])
	assert_between(she, 1.58, 1.7)
	assert_between(he, 1.71, 1.83)


func test_age_shows() -> void:
	var old_grey := 0
	var old := 0
	var young_grey := 0
	var young := 0
	for p: PersonInfo in people:
		var l := _look(p)
		var grey := l.hair == FigureLook.GREY_HAIR or l.hair == FigureLook.WHITE_HAIR
		if p.age >= 70:
			old += 1
			old_grey += 1 if grey else 0
			assert_gt(l.stoop, 0.0, "an old person stoops")
			assert_lt(l.pace, 1.0, "and walks slower")
		elif p.age < 35:
			young += 1
			young_grey += 1 if grey else 0
			assert_eq(l.stoop, 0.0)
	assert_gt(old, 5)
	assert_gt(float(old_grey) / old, 0.5, "most old people are grey")
	assert_lt(float(young_grey) / maxi(1, young), 0.05)


func test_realistic_tones() -> void:
	for p: PersonInfo in people.slice(0, 200):
		var l := _look(p)
		assert_has(FigureLook.SKIN, l.skin)
		for c: Color in [l.top, l.work_top, l.bottom]:
			assert_lte(c.s, 0.5, "muted clothes: %s" % c)
