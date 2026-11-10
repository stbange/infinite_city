class_name FactionInfo
extends RefCounted
## A power of the city or a local faction of a Reach (spec city-history).

## "G<n>" for city-wide powers, "R<x>,<y>,<z>#<n>" for local factions.
var key: String
## authority, company, guild, party, gang, faith, society.
var type: String
var name: String
var color: Color
## Vital good a company controls (food, power, water, transit, medicine), or "".
var good: String = ""
var founded: int = 0
## Year it was dissolved, or -1 while it exists.
var dissolved: int = -1
var strength: float = 0.5
var home_district := Vector3i.ZERO


func _init(p_key: String, p_type: String, p_name: String, p_color: Color, p_founded: int) -> void:
	key = p_key
	type = p_type
	name = p_name
	color = p_color
	founded = p_founded


## True when the faction exists in `year`: founded by then and not dissolved before it.
func exists_at(year: int) -> bool:
	return founded <= year and (dissolved < 0 or dissolved >= year)


func is_global() -> bool:
	return key.begins_with("G")
