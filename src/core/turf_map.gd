class_name TurfMap
extends RefCounted
## Gang claims on bridges (spec gang-turf / Bridge claims): the gang owning the bridge's district,
## or a gang of the Reach whose home district is next to it.

const SALT_TURF := 170
const NEIGHBOUR_CLAIM := 0.3
const CACHE := 2048

var chronicle: CityChronicle
var layout: CityLayout
## Claims changed by events (spec event-log); null for the baseline only.
var overlays: WorldOverlays
var _claims: Dictionary = {}   # "cell|axis" -> gang key or ""


func _init(p_chronicle: CityChronicle, p_layout: CityLayout) -> void:
	chronicle = p_chronicle
	layout = p_layout


## Key of the gang claiming a bridge, or "" (events first, then the baseline).
func claim_of(bridge: BridgeInfo) -> String:
	var key := "%s|%d" % [bridge.cell_a, bridge.axis]
	if overlays != null:
		var changed := overlays.claim_override(key)
		if not changed.is_empty():
			return changed
	if _claims.has(key):
		return _claims[key]
	var claim := _claim(bridge)
	if _claims.size() >= CACHE:
		_claims.clear()
	_claims[key] = claim
	return claim


func _claim(bridge: BridgeInfo) -> String:
	var district := layout.district_of(bridge.cell_a)
	var owner := chronicle.owner_of_district(district)
	if owner.is_empty():
		return ""
	var owner_faction := chronicle.faction(owner)
	if owner_faction != null and owner_faction.type == "gang":
		return owner
	var reach := chronicle.reach(CityChronicle.reach_of(district))
	var year := CityHistory.PRESENT_YEAR
	for i in reach.factions.size():
		var gang := reach.factions[i]
		if gang.type != "gang" or not gang.exists_at(year):
			continue
		var d := gang.home_district - district
		if maxi(absi(d.x), maxi(absi(d.y), absi(d.z))) > 1:
			continue
		var c := bridge.cell_a
		var h := DetHash.hash4(layout.config.world_seed, SALT_TURF, c.x, c.y, c.z, bridge.axis * 64 + i)
		if DetHash.u01(h) < NEIGHBOUR_CLAIM:
			return gang.key
	return ""


func gang(key: String) -> FactionInfo:
	return chronicle.faction(key) if not key.is_empty() else null
