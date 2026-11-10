class_name Population
extends RefCounted
## Residents and workplaces of the city (specs residents, workplaces), generated lazily from the
## seed: households per flat, persons on demand, workplaces per unit, job markets per district.

const SALT_HOUSEHOLD := 130
const SALT_PERSON := 131
const SALT_SKILL := 132
const SALT_CULTURE := 133
const SALT_WORKPLACE := 134
const SALT_LINE := 136
const BLOCK_CACHE := 64
const VACANCY := 0.08
const MEMBERSHIP_CHANCE := 0.22
const PLAN_CACHE := 4096
const MARKET_CACHE := 6

var layout: CityLayout
var chronicle: CityChronicle
var interiors: InteriorLayout
var names: NameGenerator
var skills: Array = []

var _plans: Dictionary = {}
var _markets: Dictionary = {}
var _market_order: Array[Vector3i] = []
var _axes: Array = []
var _work_kinds: Dictionary = {}
var _words: Array = []
var _mutex := Mutex.new()
var _block_people: Dictionary = {}
var _block_order: Array[Vector3i] = []


func _init(p_layout: CityLayout, p_chronicle: CityChronicle) -> void:
	layout = p_layout
	chronicle = p_chronicle
	interiors = InteriorLayout.new(layout, PocketLayout.new(layout))
	names = NameGenerator.new(layout.config.world_seed)
	_axes = DataTables.load_table("traits").data["axes"]
	var work: Dictionary = DataTables.load_table("workplaces").data
	_work_kinds = work["kinds"]
	_words = work["words"]
	skills = work["skills"]


func world_seed() -> int:
	return layout.config.world_seed


func plan_of(block: BlockInfo) -> InteriorPlan:
	_mutex.lock()
	var plan: InteriorPlan = _plans.get(block.cell)
	_mutex.unlock()
	if plan != null:
		return plan
	plan = interiors.plan_of(block)
	_mutex.lock()
	if _plans.size() >= PLAN_CACHE:
		_plans.clear()
	_plans[block.cell] = plan
	_mutex.unlock()
	return plan


## (floor, unit index) of every flat of a housing block.
func flats_of(block: BlockInfo) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if block.kind != BlockTypes.Kind.HOUSING:
		return result
	var plan := plan_of(block)
	for k in plan.floors:
		for unit in plan.units:
			if not unit.is_core:
				result.append(Vector2i(k, unit.index))
	return result


# --- Households and persons --------------------------------------------------------------

## Naming culture of a district: by Reach, leaning towards the farm culture deep down.
func culture_of(district: Vector3i) -> int:
	var reach := CityChronicle.reach_of(district)
	var h := DetHash.hash3(world_seed(), SALT_CULTURE, reach.x, reach.y, reach.z)
	var depth := -district.y
	var count := names.culture_count()
	if DetHash.u01(h) < clampf(depth / 120.0, 0.0, 0.6):
		return 1   # deep farm layers
	return h % count


func household(cell: Vector3i, floor_index: int, unit_index: int) -> Household:
	var block := layout.block_at(cell)
	if block == null or block.kind != BlockTypes.Kind.HOUSING:
		return Household.new()
	return household_in(block, plan_of(block), floor_index, unit_index, culture_of(layout.district_of(cell)))


## Household of a flat when the block, its plan and the district's culture are known (fast path).
func household_in(block: BlockInfo, plan: InteriorPlan, floor_index: int, unit_index: int, culture: int) -> Household:
	var result := Household.new()
	var cell := block.cell
	if unit_index >= plan.units.size() or plan.units[unit_index].is_core or floor_index >= plan.floors:
		return result
	var rng := CellRandom.new(DetHash.hash4(world_seed(), SALT_HOUSEHOLD, cell.x, cell.y, cell.z, floor_index * 128 + unit_index))
	result.culture = culture
	if rng.next_float() < VACANCY:
		return result
	var area := plan.units[unit_index].rect.get_area()
	var roll := rng.next_float()
	if area < 90.0:
		result.type = "single" if roll < 0.55 else ("couple" if roll < 0.9 else "flatmates")
	else:
		result.type = "family" if roll < 0.45 else ("couple" if roll < 0.7 else ("flatmates" if roll < 0.85 else "single"))
	match result.type:
		"single":
			result.ages.append(rng.range_int(18, 88))
		"couple":
			var a := rng.range_int(20, 85)
			result.ages.append(a)
			result.ages.append(clampi(a + rng.range_int(-8, 8), 18, 90))
		"flatmates":
			for i in rng.range_int(2, 4):
				result.ages.append(rng.range_int(18, 40))
		"family":
			var parent := rng.range_int(26, 55)
			result.ages.append(parent)
			if rng.next_float() < 0.8:
				result.ages.append(clampi(parent + rng.range_int(-6, 6), 22, 60))
			for i in rng.range_int(1, 3):
				result.ages.append(rng.range_int(0, mini(17, parent - 16)))
			if rng.next_float() < 0.15 and result.ages.size() < 6:
				result.ages.append(rng.range_int(68, 90))
	return result


func residents(cell: Vector3i, floor_index: int, unit_index: int) -> Array[PersonInfo]:
	var result: Array[PersonInfo] = []
	var house := household(cell, floor_index, unit_index)
	if house.is_vacant():
		return result
	for slot in house.ages.size():
		result.append(_person(PersonId.of(layout, cell, floor_index, unit_index, slot), house))
	return result


func person(id: PersonId) -> PersonInfo:
	var cell := id.cell(layout)
	var house := household(cell, id.floor_index(), id.unit_index())
	if id.slot() >= house.ages.size():
		return null
	return _person(id, house)


## Per-person hash shared by the skill and the job draw (one hash per adult in a job market).
func work_hash(id: PersonId) -> int:
	return work_hash_local(id.district, id.local)


func work_hash_local(district: Vector3i, local: int) -> int:
	return DetHash.hash4(world_seed(), SALT_SKILL, district.x, district.y, district.z, local)


func skill_of(id: PersonId) -> int:
	return work_hash(id) % skills.size()


## Seed of a flat's family name: its family line, so relatives in a block share the name.
func family_seed_of(cell: Vector3i, floor_index: int, unit_index: int) -> int:
	var block := layout.block_at(cell)
	var line := line_of(block, plan_of(block), floor_index, unit_index) if block != null else 0
	return DetHash.hash4(world_seed(), SALT_HOUSEHOLD + 100, cell.x, cell.y, cell.z, line)


## Family line of a flat within its block (about five households share one).
func line_of(block: BlockInfo, plan: InteriorPlan, floor_index: int, unit_index: int) -> int:
	var flats := 0
	for unit in plan.units:
		if not unit.is_core:
			flats += 1
	var lines := maxi(1, flats * plan.floors / 5)
	return DetHash.hash4(world_seed(), SALT_LINE, block.cell.x, block.cell.y, block.cell.z, floor_index * 128 + unit_index) % lines


## Everyone living in a housing block, cached (spec relations / Fast relations).
func block_people(block: BlockInfo) -> BlockPeople:
	_mutex.lock()
	var cached: BlockPeople = _block_people.get(block.cell)
	_mutex.unlock()
	if cached != null:
		return cached
	var people := BlockPeople.new()
	if block.kind == BlockTypes.Kind.HOUSING:
		var plan := plan_of(block)
		var culture := culture_of(layout.district_of(block.cell))
		var district := layout.district_of(block.cell)
		var local_cell := layout.local_in_district(block.cell)
		for k in plan.floors:
			for unit in plan.units:
				if unit.is_core:
					continue
				var house := household_in(block, plan, k, unit.index, culture)
				var line := line_of(block, plan, k, unit.index) if house.type != "flatmates" else -1
				for slot in house.ages.size():
					var id := PersonId.new(district, PersonId.pack(local_cell, k, unit.index, slot))
					var faction := membership_of(id, house.ages[slot])
					people.add(id, house.ages[slot], k, unit.index, slot, line, house.type,
							faction.key if faction != null else "")
	_mutex.lock()
	if _block_people.size() >= BLOCK_CACHE:
		_block_people.erase(_block_order.pop_front())
	_block_people[block.cell] = people
	_block_order.append(block.cell)
	_mutex.unlock()
	return people


func _person(id: PersonId, house: Household) -> PersonInfo:
	var p := PersonInfo.new()
	p.id = id
	var h := DetHash.hash4(world_seed(), SALT_PERSON, id.district.x, id.district.y, id.district.z, id.local)
	var rng := CellRandom.new(h)
	p.age = house.ages[id.slot()]
	var culture := house.culture
	var family_seed := family_seed_of(id.cell(layout), id.floor_index(), id.unit_index())
	if house.type == "flatmates":
		culture = rng.next_int(names.culture_count())
		family_seed = h
	p.given_name = names.given_name(culture, h)
	p.family_name = names.family_name(culture, family_seed)
	var pronoun_roll := rng.next_float()
	p.pronoun = "she" if pronoun_roll < 0.47 else ("he" if pronoun_roll < 0.94 else "they")
	var axes: Array[int] = [0, 1, 2, 3, 4]
	for i in 3:
		var j := i + rng.next_int(axes.size() - i)
		var tmp := axes[i]
		axes[i] = axes[j]
		axes[j] = tmp
		var pair: Array = _axes[axes[i]]
		p.traits.append(pair[rng.next_int(2)])
	p.skill = skills[skill_of(id)]
	var depth := float(-id.district.y)
	p.wealth = clampf(0.65 - depth / 300.0 + rng.range_float(-0.3, 0.3), 0.0, 1.0)
	p.health = clampf(1.0 - maxf(0.0, p.age - 40) / 80.0 + rng.range_float(-0.2, 0.1), 0.0, 1.0)
	var faction := membership_of(id, p.age)
	if faction != null:
		p.membership = faction.key
		p.membership_secret = faction.type == "gang" or faction.type == "society"
	return p


## The faction a person belongs to, or null (its own hash, so it can be found without the rest).
func membership_of(id: PersonId, age: int) -> FactionInfo:
	if age < 18 or chronicle == null:
		return null
	var rng := CellRandom.new(DetHash.hash4(world_seed(), SALT_PERSON + 50, id.district.x, id.district.y, id.district.z, id.local))
	if rng.next_float() >= MEMBERSHIP_CHANCE:
		return null
	return _pick_membership(id.district, rng)


func _pick_membership(district: Vector3i, rng: CellRandom) -> FactionInfo:
	var reach := chronicle.reach(CityChronicle.reach_of(district))
	var owner := chronicle.owner_of_district(district)
	var weights: Array[float] = []
	var options: Array[FactionInfo] = []
	for faction in reach.factions:
		if faction.exists_at(CityHistory.PRESENT_YEAR):
			options.append(faction)
			weights.append(3.0 if faction.key == owner else 1.0)
	if options.is_empty():
		return null
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.next_float() * total
	for i in options.size():
		r -= weights[i]
		if r <= 0.0:
			return options[i]
	return options[-1]


## Index of the personality axis a trait word belongs to, or -1.
func axis_of_trait(word: String) -> int:
	for i in _axes.size():
		if (_axes[i] as Array).has(word):
			return i
	return -1


func trait_axes() -> Array:
	return _axes


# --- Workplaces ----------------------------------------------------------------------------

func work_kind(kind: int) -> Dictionary:
	return _work_kinds.get(BlockTypes.Kind.keys()[kind], {})


## The workplace of a unit (without slots; job markets scale those), or null for flats and cores.
func workplace(cell: Vector3i, floor_index: int, unit_index: int) -> WorkplaceInfo:
	var block := layout.block_at(cell)
	if block == null or block.kind == BlockTypes.Kind.HOUSING:
		return null
	var plan := plan_of(block)
	if unit_index >= plan.units.size() or plan.units[unit_index].is_core:
		return null
	return make_workplace(block, plan, floor_index, unit_index)


func make_workplace(block: BlockInfo, _plan: InteriorPlan, floor_index: int, unit_index: int) -> WorkplaceInfo:
	var spec := work_kind(block.kind)
	var w := WorkplaceInfo.new()
	w.id = PersonId.of(layout, block.cell, floor_index, unit_index, 0)
	w.cell = block.cell
	w.floor_index = floor_index
	w.unit = unit_index
	w.kind = block.kind
	var trades: Array = spec.get("trades", [{"name": "unit", "pattern": "Unit {n}", "food": false}])
	var h := DetHash.hash4(world_seed(), SALT_WORKPLACE, block.cell.x, block.cell.y, block.cell.z, floor_index * 128 + unit_index)
	var trade: Dictionary = trades[h % trades.size()]
	w.trade = trade["name"]
	w.is_food = trade["food"]
	w.opens = int(spec.get("opens", 8 * 60))
	w.closes = int(spec.get("closes", 18 * 60))
	w.name = _name_workplace(w, String(trade["pattern"]), h)
	return w


func _name_workplace(w: WorkplaceInfo, pattern: String, h: int) -> String:
	var culture := culture_of(layout.district_of(w.cell))
	var values := {
		"family": names.family_name(culture, h),
		"given": names.given_name(culture, h),
		"word": _words[(h >> 4) % _words.size()],
		"n": str(w.floor_index + 1) + str(w.unit + 1),
	}
	return TextTemplate.fill(pattern, values, h)


func job_market(district: Vector3i) -> JobMarket:
	_mutex.lock()
	var cached: JobMarket = _markets.get(district)
	_mutex.unlock()
	if cached != null:
		return cached
	var market := JobMarket.new(self, district)
	_mutex.lock()
	if not _markets.has(district):
		_markets[district] = market
		_market_order.append(district)
		if _market_order.size() > MARKET_CACHE:
			_markets.erase(_market_order.pop_front())
	market = _markets[district]
	_mutex.unlock()
	return market


## Takes a job market built elsewhere (for example on a worker thread with its own layout).
func adopt_market(market: JobMarket) -> void:
	market.attach(self)
	_mutex.lock()
	if not _markets.has(market.district):
		_markets[market.district] = market
		_market_order.append(market.district)
		if _market_order.size() > MARKET_CACHE:
			_markets.erase(_market_order.pop_front())
	_mutex.unlock()


## Short name for a door plate: the household's family name(s), "Vacant", or the business name.
func door_name(cell: Vector3i, floor_index: int, unit_index: int) -> String:
	var block := layout.block_at(cell)
	if block == null:
		return ""
	if block.kind != BlockTypes.Kind.HOUSING:
		var w := workplace(cell, floor_index, unit_index)
		return w.name if w != null else ""
	var people := residents(cell, floor_index, unit_index)
	if people.is_empty():
		return "Vacant"
	var families := PackedStringArray()
	for p in people:
		if not families.has(p.family_name):
			families.append(p.family_name)
	return " / ".join(families.slice(0, 2))


func has_job_market(district: Vector3i) -> bool:
	_mutex.lock()
	var found := _markets.has(district)
	_mutex.unlock()
	return found


## The workplace a person is assigned to, or null.
func workplace_of(id: PersonId) -> WorkplaceInfo:
	return job_market(id.district).workplace_of(id)
