class_name CityChronicle
extends RefCounted
## Entry point to the generated past (spec city-history): the city history plus a cache of Reach
## histories. A Reach is 4 × 4 × 4 districts.

const REACH_DISTRICTS := 4
const CACHE_SIZE := 64

var config: CityConfig
var history: CityHistory
var _cache: Dictionary = {}
var _order: Array[Vector3i] = []


func _init(p_config: CityConfig) -> void:
	config = p_config
	history = CityHistory.new(config)


static func reach_of(district: Vector3i) -> Vector3i:
	return IntMath.floor_div_v3i(district, REACH_DISTRICTS)


static func reach_of_key(key: String) -> Vector3i:
	var body := key.substr(1, key.find("#") - 1)
	var parts := body.split(",")
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))


func reach(coords: Vector3i) -> ReachHistory:
	if _cache.has(coords):
		return _cache[coords]
	var neighbours := {}
	for step: Vector3i in ReachHistory.NEIGHBOUR_STEPS:
		var gang := first_seeded_gang(coords + step)
		if gang != null:
			neighbours[step] = gang
	var result := ReachHistory.new(history, coords, neighbours)
	_cache[coords] = result
	_order.append(coords)
	if _order.size() > CACHE_SIZE:
		_cache.erase(_order.pop_front())
	return result


## The first gang a Reach's seeding founds, without simulating its history (null in the sky).
func first_seeded_gang(coords: Vector3i) -> FactionInfo:
	for faction in ReachHistory.seed_factions(history, coords):
		if faction.type == "gang":
			return faction
	return null


func faction(key: String) -> FactionInfo:
	if key.begins_with("G"):
		return history.power(key)
	if key.begins_with("R"):
		return reach(reach_of_key(key)).faction(key)
	return null


## Present owner of a district (faction key), or "" above the sky.
func owner_of_district(district: Vector3i) -> String:
	return reach(reach_of(district)).territory.owner_at(district, CityHistory.PRESENT_YEAR)
