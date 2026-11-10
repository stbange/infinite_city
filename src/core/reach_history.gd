class_name ReachHistory
extends RefCounted
## The history of one Reach (4 × 4 × 4 districts, spec city-history / Reach histories): local
## factions simulated in five-year steps from the Building Down era to the present.

const SALT_SEEDING := 114
const SALT_REACH := 115
const SALT_REACH_NAME := 116
const STEP_YEARS := 5
const MIN_ALIVE := 8
const MAX_FACTIONS := 24
const COLLAPSE_BELOW := 0.08
const NEIGHBOUR_STEPS: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0),
		Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]

var reach: Vector3i
var name: String = ""
var factions: Array[FactionInfo] = []
var events: Array[HistoryEvent] = []
var territory := Territory.new()

var _history: CityHistory
var _by_key: Dictionary = {}
var _districts: Array[Vector3i] = []
var _templates: Dictionary = {}
var _neighbours: Dictionary = {}
var _rng: CellRandom
var _alive: Array[FactionInfo] = []


func _init(history: CityHistory, coords: Vector3i, neighbours: Dictionary) -> void:
	_history = history
	reach = coords
	_neighbours = neighbours
	_districts = districts_of(history.config, coords)
	var words: Array = history.tables()["reach_words"]
	name = "%s Reach" % words[DetHash.hash3(history.config.world_seed, SALT_REACH_NAME, coords.x, coords.y, coords.z) % words.size()]
	if _districts.is_empty():
		return
	_templates = DataTables.load_table("events").data["templates"]
	_rng = CellRandom.new(DetHash.hash3(history.config.world_seed, SALT_REACH, coords.x, coords.y, coords.z))
	for faction in seed_factions(history, coords):
		_add(faction)
	_simulate()
	events.sort_custom(func(a: HistoryEvent, b: HistoryEvent) -> bool: return a.year < b.year)


## Districts of a Reach that lie at or below the roof's district.
static func districts_of(config: CityConfig, coords: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var roof := IntMath.floor_div(config.roof_layer, config.district_size)
	var n := CityChronicle.REACH_DISTRICTS
	for dy in n:
		for dz in n:
			for dx in n:
				var d := coords * n + Vector3i(dx, dy, dz)
				if d.y <= roof:
					result.append(d)
	return result


## The factions a Reach starts with, from the seed and the Reach alone (neighbours use this too).
static func seed_factions(history: CityHistory, coords: Vector3i) -> Array[FactionInfo]:
	var result: Array[FactionInfo] = []
	var districts := districts_of(history.config, coords)
	if districts.is_empty():
		return result
	var rng := CellRandom.new(DetHash.hash3(history.config.world_seed, SALT_SEEDING, coords.x, coords.y, coords.z))
	var plan: Array[String] = []
	for i in rng.range_int(3, 5):
		plan.append("gang")
	for i in rng.range_int(2, 3):
		plan.append("party")
	for i in rng.range_int(1, 3):
		plan.append("guild")
	for i in rng.range_int(0, 2):
		plan.append("company")
	for i in rng.range_int(0, 2):
		plan.append("faith")
	var used := {}
	for type in plan:
		var faction := _make_faction(history, coords, result.size(), type, rng, used, -1)
		faction.home_district = districts[rng.next_int(districts.size())]
		result.append(faction)
	return result


static func _make_faction(history: CityHistory, coords: Vector3i, index: int, type: String, rng: CellRandom,
		used: Dictionary, founded: int) -> FactionInfo:
	var tables := history.tables()
	var key := "R%d,%d,%d#%d" % [coords.x, coords.y, coords.z, index]
	if founded < 0:
		var first_era := 1 if type in ["guild", "company"] else 2
		var era := history.eras[rng.range_int(first_era, history.eras.size() - 1)]
		founded = rng.range_int(era.start_year, maxi(era.start_year, era.end_year - 1))
	var name := ""
	for attempt in 12:
		name = _faction_name(history, type, rng, tables)
		if not used.has(name):
			break
	if used.has(name):
		name = "%s of %s" % [name, history.names.family_name(0, index * 7 + coords.x)]
	used[name] = true
	var colors: Array = tables["colors"]
	var faction := FactionInfo.new(key, type, name, Color(colors[rng.next_int(colors.size())]), founded)
	faction.strength = rng.range_float(0.25, 0.7)
	return faction


static func _faction_name(history: CityHistory, type: String, rng: CellRandom, tables: Dictionary) -> String:
	match type:
		"gang":
			var first: Array = tables["gang_first"]
			var second: Array = tables["gang_second"]
			return "the %s %s" % [first[rng.next_int(first.size())], second[rng.next_int(second.size())]]
		"party":
			var parties: Array = tables["party_names"]
			return parties[rng.next_int(parties.size())]
		"guild":
			var guilds: Array = tables["guild_names"]
			return guilds[rng.next_int(guilds.size())]
		"faith":
			var faiths: Array = tables["local_faith_names"]
			return faiths[rng.next_int(faiths.size())]
	var suffixes: Array = tables["local_company_suffix"]
	return "%s %s" % [history.names.family_name(rng.next_int(history.names.culture_count()), rng.next_int(1 << 30)),
			suffixes[rng.next_int(suffixes.size())]]


func districts() -> Array[Vector3i]:
	return _districts


func faction(key: String) -> FactionInfo:
	return _by_key.get(key) as FactionInfo


func owns_key(key: String) -> bool:
	return _by_key.has(key)


## Faction (local or city-wide) by key, for names in event texts.
func _lookup(key: String) -> FactionInfo:
	return _by_key[key] if _by_key.has(key) else _history.power(key)


func _add(faction: FactionInfo) -> void:
	factions.append(faction)
	_by_key[faction.key] = faction


# --- Simulation ----------------------------------------------------------------------------

func _simulate() -> void:
	var start := _history.era_of_kind("building_down").start_year
	for district in _districts:
		territory.claim(district, start, _strongest_power(district, start))
	var activated := {}
	var war := _history.era_of_kind("war")
	var year := start
	while year <= CityHistory.PRESENT_YEAR:
		var snapshot: Array[FactionInfo] = factions.duplicate()
		for faction in snapshot:
			if not activated.has(faction.key) and faction.founded <= year and faction.dissolved < 0:
				activated[faction.key] = true
				_alive.append(faction)
				_event(faction.founded, "founding", [faction.key], faction.home_district)
				if faction.type == "gang":
					_claim_home(faction, maxi(faction.founded, year))
		var living: Array[FactionInfo] = _alive.duplicate()
		for faction in living:
			if faction.dissolved >= 0:
				continue
			faction.strength = clampf(faction.strength + _rng.range_float(-0.03, 0.03), 0.0, 1.2)
			_act(faction, year)
			if faction.strength < COLLAPSE_BELOW:
				_collapse(faction, year)
		if war.contains(year):
			_war_damage(year)
		_replenish(year)
		year += STEP_YEARS
	_ensure_types()


func _act(faction: FactionInfo, year: int) -> void:
	var roll := _rng.next_float()
	match faction.type:
		"gang":
			if roll < 0.14:
				_takeover(faction, year)
			elif roll < 0.20:
				_feud(faction, year)
			elif roll < 0.23 and faction == _strongest_of("gang"):
				_border_feud(faction, year)
			elif roll < 0.235:
				_split(faction, year)
		"company":
			if roll < 0.08:
				_buyout(faction, year)
			elif roll < 0.09:
				_split(faction, year)
		"guild":
			if roll < 0.08:
				_strike(faction, year)
			elif roll < 0.095:
				_alliance(faction, year)
		"party":
			if roll < 0.035:
				faction.strength += 0.05
				_event(year, "election", [faction.key])
			elif roll < 0.055:
				_alliance(faction, year)
			elif roll < 0.065:
				_split(faction, year)
		"faith":
			if roll < 0.06:
				faction.strength += 0.04
				_event(year, "revival", [faction.key])


## A new gang takes its home district from a city-wide owner.
func _claim_home(gang: FactionInfo, year: int) -> void:
	var owner := _lookup(territory.owner_at(gang.home_district, year))
	if owner == null or not owner.is_global():
		return
	territory.claim(gang.home_district, year, gang.key)
	_event(year, "takeover", [gang.key, owner.key], gang.home_district)


func _takeover(gang: FactionInfo, year: int) -> void:
	var target := _pick_target(gang, year)
	var owner_key := territory.owner_at(target, year)
	if owner_key == gang.key:
		return
	var owner := _lookup(owner_key)
	var defence := _defence(owner, target)
	if owner.type == "gang" and defence > gang.strength:
		_feud_between(gang, owner, year)
		return
	if gang.strength * _rng.range_float(0.6, 1.4) < defence * 0.7:
		return
	territory.claim(target, year, gang.key)
	gang.strength += 0.05
	if not owner.is_global():
		owner.strength -= 0.06
	_event(year, "takeover", [gang.key, owner.key], target)


## A district next to the faction's turf (or its home), preferring ones it does not own.
func _pick_target(faction: FactionInfo, year: int) -> Vector3i:
	var owned: Array[Vector3i] = []
	for d in _districts:
		if territory.owner_at(d, year) == faction.key:
			owned.append(d)
	var base := faction.home_district if owned.is_empty() else owned[_rng.next_int(owned.size())]
	var candidates: Array[Vector3i] = []
	for step in NEIGHBOUR_STEPS:
		var d := base + step
		if _districts.has(d) and territory.owner_at(d, year) != faction.key:
			candidates.append(d)
	if candidates.is_empty():
		return _districts[_rng.next_int(_districts.size())]
	return candidates[_rng.next_int(candidates.size())]


func _defence(owner: FactionInfo, district: Vector3i) -> float:
	if owner.is_global():
		return _history.influence(owner.key, district) * owner.strength
	return owner.strength


func _feud(gang: FactionInfo, year: int) -> void:
	var rivals: Array[FactionInfo] = []
	for other in _alive:
		if other != gang and other.type == "gang" and other.dissolved < 0:
			rivals.append(other)
	if not rivals.is_empty():
		_feud_between(gang, rivals[_rng.next_int(rivals.size())], year)


func _feud_between(a: FactionInfo, b: FactionInfo, year: int) -> void:
	a.strength -= 0.04
	b.strength -= 0.04
	if _rng.next_int(2) == 0:
		a.strength -= 0.06
	else:
		b.strength -= 0.06
	_event(year, "feud", [a.key, b.key])


func _border_feud(gang: FactionInfo, year: int) -> void:
	var step := NEIGHBOUR_STEPS[_rng.next_int(NEIGHBOUR_STEPS.size())]
	var other: FactionInfo = _neighbours.get(step)
	if other == null or other.founded > year:
		return
	gang.strength -= 0.03
	_event(year, "border_feud", [gang.key, other.key])


func _buyout(company: FactionInfo, year: int) -> void:
	var target := _pick_target(company, year)
	var owner := _lookup(territory.owner_at(target, year))
	if owner.type == "gang" or owner == company:
		return
	if company.strength < _defence(owner, target) * 0.6:
		return
	territory.claim(target, year, company.key)
	company.strength += 0.03
	_event(year, "buyout", [company.key, owner.key], target)


func _strike(guild: FactionInfo, year: int) -> void:
	var companies: Array[FactionInfo] = []
	for p in _history.powers:
		if p.type == "company" and p.exists_at(year):
			companies.append(p)
	for f in _alive:
		if f.type == "company" and f.dissolved < 0:
			companies.append(f)
	if companies.is_empty():
		return
	var target := companies[_rng.next_int(companies.size())]
	guild.strength += _rng.range_float(-0.05, 0.08)
	_event(year, "strike", [guild.key, target.key])


func _alliance(faction: FactionInfo, year: int) -> void:
	var partners: Array[FactionInfo] = []
	for other in _alive:
		if other != faction and other.dissolved < 0 and other.type in ["party", "guild", "faith"]:
			partners.append(other)
	if partners.is_empty():
		return
	var partner := partners[_rng.next_int(partners.size())]
	faction.strength += 0.02
	partner.strength += 0.02
	_event(year, "alliance", [faction.key, partner.key])


func _split(parent: FactionInfo, year: int) -> void:
	if parent.strength < 0.6 or factions.size() >= MAX_FACTIONS:
		return
	var child := _found(parent.type, year)
	child.home_district = parent.home_district
	parent.strength -= 0.2
	child.strength = 0.25
	_event(year, "split", [child.key, parent.key])


func _collapse(faction: FactionInfo, year: int) -> void:
	faction.dissolved = year
	_alive.erase(faction)
	_event(year, "collapse", [faction.key])
	for d in _districts:
		if territory.owner_at(d, year) == faction.key:
			territory.claim(d, year, _strongest_power(d, year))


func _war_damage(year: int) -> void:
	var antagonist := _history.power(_history.war_antagonist)
	if antagonist == null or _rng.next_float() > 0.3:
		return
	var target := _districts[_rng.next_int(_districts.size())]
	var kind := "blackout" if antagonist.good == "power" else "raid"
	_event(year, kind, [antagonist.key], target)


func _replenish(year: int) -> void:
	var alive := 0
	for f in _alive:
		if f.dissolved < 0:
			alive += 1
	if alive >= MIN_ALIVE or factions.size() >= MAX_FACTIONS:
		return
	var types: Array[String] = ["gang", "gang", "party", "guild", "company", "faith"]
	var faction := _found(types[_rng.next_int(types.size())], year)
	faction.home_district = _districts[_rng.next_int(_districts.size())]


## Makes sure a gang, a party and a guild are alive at the present.
func _ensure_types() -> void:
	for type: String in ["gang", "party", "guild"]:
		var alive := false
		for f in factions:
			if f.type == type and f.exists_at(CityHistory.PRESENT_YEAR):
				alive = true
		if not alive:
			var year := _rng.range_int(480, CityHistory.PRESENT_YEAR)
			var faction := _found(type, year)
			faction.home_district = _districts[_rng.next_int(_districts.size())]
			_alive.append(faction)
			_event(year, "founding", [faction.key], faction.home_district)


## A new local faction founded in `year` (activated by the simulation loop when it gets there).
func _found(type: String, year: int) -> FactionInfo:
	var used := {}
	for f in factions:
		used[f.name] = true
	var faction := _make_faction(_history, reach, factions.size(), type, _rng, used, year)
	_add(faction)
	return faction


func _strongest_power(district: Vector3i, year: int) -> String:
	var best := ""
	var best_value := -1.0
	for p in _history.powers:
		if (p.type == "company" or p.type == "authority") and p.exists_at(year):
			var value := _history.influence(p.key, district) * p.strength
			if value > best_value:
				best_value = value
				best = p.key
	return best


func _strongest_of(type: String) -> FactionInfo:
	var best: FactionInfo = null
	for f in _alive:
		if f.type == type and f.dissolved < 0 and (best == null or f.strength > best.strength):
			best = f
	return best


func _event(year: int, kind: String, actors: Array, district: Variant = null) -> void:
	var keys := PackedStringArray()
	for key: String in actors:
		keys.append(key)
	var values := {}
	if keys.size() > 0:
		values["a"] = _name_of(keys[0])
	if keys.size() > 1:
		values["b"] = _name_of(keys[1])
	if district is Vector3i:
		values["district"] = "district %d,%d,%d" % [district.x, district.y, district.z]
	var variants: Array = _templates.get(kind, ["{a}"])
	var seed_value := DetHash.hash3(year, events.size(), reach.x, reach.y, reach.z)
	var text := TextTemplate.fill(variants[0], values, seed_value)
	var event := HistoryEvent.new(year, kind, keys, text[0].to_upper() + text.substr(1))
	if district is Vector3i:
		event.at_district(district)
	events.append(event)


func _name_of(key: String) -> String:
	var f := _lookup(key)
	if f != null:
		return f.name
	for step: Vector3i in _neighbours:
		var other: FactionInfo = _neighbours[step]
		if other.key == key:
			return other.name
	return key
