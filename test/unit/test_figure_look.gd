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
			assert_between(l.height, 1.4, 2.0, "adult %d" % p.age)
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


func test_body_types_vary() -> void:
	var counts := {}
	var heavy_young := 0
	var young := 0
	var heavy_older := 0
	var older := 0
	var adults := 0
	for p: PersonInfo in people:
		if p.age < 18:
			continue
		adults += 1
		var l := _look(p)
		counts[l.build] = counts.get(l.build, 0) + 1
		if l.build == FigureLook.Build.HEAVY:
			assert_gt(l.belly, 0.0, "a heavy body has a belly")
		else:
			assert_eq(l.belly, 0.0)
		if p.age < 30:
			young += 1
			heavy_young += 1 if l.build == FigureLook.Build.HEAVY else 0
		elif p.age >= 45:
			older += 1
			heavy_older += 1 if l.build == FigureLook.Build.HEAVY else 0
	for b: int in FigureLook.Build.values():
		assert_gt(float(counts.get(b, 0)) / adults, 0.04, "build %d appears" % b)
	assert_gt(float(heavy_older) / maxi(1, older), float(heavy_young) / maxi(1, young), "heavier with age")


func test_womens_figures() -> void:
	var women := 0
	var skirted := 0
	for p: PersonInfo in people:
		var l := _look(p)
		if p.pronoun == "he":
			assert_eq(l.bust, 0.0)
			assert_eq(l.garment, FigureLook.Garment.TROUSERS)
		elif p.pronoun == "she" and p.age >= 18:
			women += 1
			assert_gt(l.bust, 0.3, "a woman has a bust")
			assert_lt(l.waist, l.hips, "and a waist narrower than her hips")
			skirted += 1 if l.garment != FigureLook.Garment.TROUSERS else 0
	assert_gt(women, 50)
	assert_between(float(skirted) / women, 0.3, 0.7, "many but not all women wear skirts or dresses")
