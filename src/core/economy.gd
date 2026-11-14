class_name Economy
extends RefCounted
## The numbers that decide how the game feels (spec economy-tables): pay, rent, tolls, chases,
## fees and price drift, read from data/economy.json. Tests and tuning may override single values.

const SECTIONS := ["orders", "pay", "rent", "encounters", "hazards", "live", "shop", "licences"]

static var _overrides: Dictionary = {}


static func num(section: String, key: String) -> float:
	var path := section + "." + key
	if _overrides.has(path):
		return float(_overrides[path])
	var data: Dictionary = DataTables.load_table("economy").data
	return float((data[section] as Dictionary)[key])


static func whole(section: String, key: String) -> int:
	return roundi(num(section, key))


## Replaces one value until clear_overrides() (tuning and tests).
static func set_override(section: String, key: String, value: float) -> void:
	_overrides[section + "." + key] = value


static func clear_overrides() -> void:
	_overrides.clear()
