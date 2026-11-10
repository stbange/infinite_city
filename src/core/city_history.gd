class_name CityHistory
extends RefCounted
## The city's history for one seed (spec city-history): six eras from year 0 to the present,
## the city-wide powers, the war, and the legends.

const PRESENT_YEAR := 517
const SALT_HISTORY := 110
const SALT_POWERS := 111
const SALT_LEGENDS := 112

var config: CityConfig
var eras: Array[EraInfo] = []
var powers: Array[FactionInfo] = []
var legends: Array[LegendInfo] = []
## City-wide events: era beginnings and the legends' deeds.
var events: Array[HistoryEvent] = []
## Key of the company the war era was fought against.
var war_antagonist: String = ""
var war_won_by_districts: bool = true
var names: NameGenerator

var _powers_by_key: Dictionary = {}
var _tables: Dictionary = {}


func _init(p_config: CityConfig) -> void:
	config = p_config
	names = NameGenerator.new(config.world_seed)
	_tables = DataTables.load_table("factions").data
	_make_eras()
	_make_powers()
	_make_war()
	_make_legends()
	events.sort_custom(func(a: HistoryEvent, b: HistoryEvent) -> bool: return a.year < b.year)


func power(key: String) -> FactionInfo:
	return _powers_by_key.get(key) as FactionInfo


func era_at(year: int) -> EraInfo:
	for era in eras:
		if era.contains(year):
			return era
	return eras[-1] if year == PRESENT_YEAR else null


func era_of_kind(kind: String) -> EraInfo:
	for era in eras:
		if era.kind == kind:
			return era
	return null


## District row that holds the roof layer (its top layer); rows above it are sky.
static func roof_district_row(p_config: CityConfig) -> int:
	return IntMath.floor_div(-1, p_config.district_size)


## District layers below the roof's district (0 at the roof's district).
func depth_of(district: Vector3i) -> float:
	return float(roof_district_row(config) - district.y)


func influence(key: String, district: Vector3i) -> float:
	var p := power(key)
	if p == null:
		return 0.0
	return InfluenceField.strength(config.world_seed, powers.find(p), p.type, p.good, district, depth_of(district))


## Faction tables (data/factions.json).
func tables() -> Dictionary:
	return _tables


## A one-line-per-fact summary (used to compare histories).
func describe() -> String:
	var lines := PackedStringArray()
	for era in eras:
		lines.append("%d-%d %s" % [era.start_year, era.end_year, era.name])
	for p in powers:
		lines.append("%s %s %s %s" % [p.key, p.type, p.name, p.good])
	for legend in legends:
		lines.append("%s %d %d %s" % [legend.name, legend.born, legend.died, legend.role])
	return "\n".join(lines)


func _rng(salt: int, part: int) -> CellRandom:
	return CellRandom.new(DetHash.hash2(config.world_seed, salt, part, 0))


func _make_eras() -> void:
	var table: Dictionary = DataTables.load_table("eras").data
	var specs: Array = table["eras"]
	var rng := _rng(SALT_HISTORY, 1)
	var last: Dictionary = specs[-1]
	var quiet := rng.range_int(int(last["min_years"]), int(last["max_years"]))
	var lengths: Array[float] = []
	var total := 0.0
	for i in specs.size() - 1:
		var length := float(rng.range_int(int(specs[i]["min_years"]), int(specs[i]["max_years"])))
		lengths.append(length)
		total += length
	var available := PRESENT_YEAR - quiet
	var year := 0
	for i in specs.size():
		var spec: Dictionary = specs[i]
		var end := PRESENT_YEAR
		if i < specs.size() - 1:
			end = year + maxi(1, roundi(lengths[i] * available / total))
			if i == specs.size() - 2:
				end = available
		var names_list: Array = spec["names"]
		eras.append(EraInfo.new(spec["kind"], names_list[rng.next_int(names_list.size())], year, end))
		year = end


func _make_powers() -> void:
	var rng := _rng(SALT_POWERS, 1)
	var colors: Array = _shuffled(_tables["colors"], rng)
	var raising := eras[0]
	var used_names := {}
	var authority_names: Array = _tables["authority_names"]
	_add_power("authority", authority_names[rng.next_int(authority_names.size())], "", colors, raising.start_year, rng)
	var goods: Array = _shuffled(_tables["goods"], rng)
	var company_count := rng.range_int(3, 5)
	for i in company_count:
		var good: String = goods[i]
		var suffixes: Array = (_tables["company_suffix"] as Dictionary)[good]
		var name := ""
		for attempt in 10:
			var family := names.family_name(rng.next_int(names.culture_count()), rng.next_int(1 << 30))
			if rng.next_int(2) == 0:
				family += "-" + names.family_name(rng.next_int(names.culture_count()), rng.next_int(1 << 30))
			name = "%s %s" % [family, suffixes[rng.next_int(suffixes.size())]]
			if not used_names.has(name):
				break
		used_names[name] = true
		var founded := raising.start_year + rng.range_int(2, mini(20, raising.end_year - 1))
		var company := _add_power("company", name, good, colors, founded, rng)
		company.good = good
	var faiths: Array = _shuffled(_tables["faith_names"], rng)
	for i in rng.range_int(1, 2):
		var era := eras[rng.range_int(1, 4)]
		_add_power("faith", faiths[i], "", colors, rng.range_int(era.start_year, era.end_year - 1), rng)
	var societies: Array = _tables["society_names"]
	var rush := era_of_kind("doorway_rush")
	_add_power("society", societies[rng.next_int(societies.size())], "", colors,
			rng.range_int(rush.start_year, rush.end_year - 1), rng)


func _add_power(type: String, name: String, good: String, colors: Array, founded: int, rng: CellRandom) -> FactionInfo:
	var key := "G%d" % powers.size()
	var color := Color(colors[powers.size() % colors.size()])
	var faction := FactionInfo.new(key, type, name, color, founded)
	faction.good = good
	faction.strength = rng.range_float(0.6, 1.0)
	powers.append(faction)
	_powers_by_key[key] = faction
	return faction


func _make_war() -> void:
	var rng := _rng(SALT_HISTORY, 2)
	var companies: Array[FactionInfo] = []
	for p in powers:
		if p.type == "company":
			companies.append(p)
	var antagonist := companies[rng.next_int(companies.size())]
	war_antagonist = antagonist.key
	war_won_by_districts = rng.next_float() < 0.6
	var war := era_of_kind("war")
	var war_names: Dictionary = DataTables.load_table("eras").data["war_names"]
	war.name = war_names.get(antagonist.good, "the War")
	if not war_won_by_districts:
		antagonist.strength = minf(1.0, antagonist.strength + 0.2)
	else:
		antagonist.strength *= 0.7
	for era in eras:
		events.append(HistoryEvent.new(era.start_year, "era", PackedStringArray(), "%s began." % era.name.capitalize()))


func _make_legends() -> void:
	var table: Dictionary = DataTables.load_table("eras").data
	var specs: Array = table["eras"]
	var rng := _rng(SALT_LEGENDS, 1)
	for i in eras.size():
		var era := eras[i]
		var spec: Dictionary = specs[i]
		var roles: Array = spec["roles"]
		var deeds: Array = spec["deeds"]
		for n in rng.range_int(2, 3):
			var legend := LegendInfo.new()
			var role_index := rng.next_int(roles.size())
			legend.role = roles[role_index]
			var year := rng.range_int(era.start_year, maxi(era.start_year, era.end_year - 1))
			legend.born = year - rng.range_int(16, 60)
			var died := legend.born + rng.range_int(45, 95)
			if died <= year:
				died = year + rng.range_int(1, 20)
			if died > PRESENT_YEAR:
				died = -1 if PRESENT_YEAR - legend.born <= 95 else rng.range_int(year + 1, PRESENT_YEAR)
			legend.died = died
			var culture := 0 if i < 2 else rng.next_int(names.culture_count())
			var id := DetHash.hash2(config.world_seed, SALT_LEGENDS, i, n)
			legend.name = names.full_name(culture, id)
			legend.faction_key = _legend_faction(era.kind, rng)
			var faction := power(legend.faction_key)
			var text := "%s, %s of %s, %s." % [legend.name, legend.role, faction.name, deeds[role_index % deeds.size()]]
			legend.event = HistoryEvent.new(year, "legend", PackedStringArray([legend.faction_key]), text)
			legends.append(legend)
			events.append(legend.event)


func _legend_faction(kind: String, rng: CellRandom) -> String:
	var wanted := ""
	match kind:
		"raising", "sealing", "building_down":
			wanted = "authority"
		"doorway_rush":
			wanted = "society"
		"war":
			return war_antagonist if rng.next_int(2) == 0 else powers[0].key
	var matching: Array[FactionInfo] = []
	for p in powers:
		if wanted.is_empty() or p.type == wanted:
			matching.append(p)
	if matching.is_empty():
		return powers[0].key
	return matching[rng.next_int(matching.size())].key


static func _shuffled(list: Array, rng: CellRandom) -> Array:
	var copy := list.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.next_int(i + 1)
		var tmp: Variant = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy
