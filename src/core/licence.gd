class_name Licence
extends RefCounted
## Couriers' Mutual licences (spec courier-progression / Licences and cargo tiers).

const LEVELS: Array[String] = ["bronze", "silver", "gold"]
## Standing and fee each level needs, from the economy table.
static var REQUIREMENTS: Dictionary:
	get:
		return {
			"silver": {"mutual": Economy.whole("licences", "silver_mutual"), "fee": Economy.whole("licences", "silver_fee")},
			"gold": {"mutual": Economy.whole("licences", "gold_mutual"), "fee": Economy.whole("licences", "gold_fee")},
		}


## Highest cargo tier: bronze 1, silver 2, gold 3 and escorts (tier 4).
static func max_tier(level: String) -> int:
	var i := LEVELS.find(level)
	return 4 if i == LEVELS.size() - 1 else i + 1


static func next_level(level: String) -> String:
	var i := LEVELS.find(level)
	return LEVELS[i + 1] if i >= 0 and i + 1 < LEVELS.size() else ""


static func can_upgrade(level: String, reputation: Reputation, credits: int) -> bool:
	var next := next_level(level)
	if next.is_empty():
		return false
	var need: Dictionary = REQUIREMENTS[next]
	return reputation.of(Reputation.MUTUAL) >= int(need["mutual"]) and credits >= int(need["fee"])


static func fee(level: String) -> int:
	var next := next_level(level)
	return int(REQUIREMENTS[next]["fee"]) if not next.is_empty() else 0
