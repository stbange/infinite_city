class_name HistoryEvent
extends RefCounted
## One event of the city's or a Reach's history (spec city-history).

var year: int
## founding, takeover, feud, border_feud, alliance, election, strike, split, collapse, buyout,
## raid, blackout, revival, legend, era.
var kind: String
## Faction keys taking part: the actor first, then the other side.
var actors := PackedStringArray()
var district := Vector3i.ZERO
var has_district: bool = false
var text: String = ""


func _init(p_year: int, p_kind: String, p_actors: PackedStringArray, p_text: String = "") -> void:
	year = p_year
	kind = p_kind
	actors = p_actors
	text = p_text


func at_district(p_district: Vector3i) -> HistoryEvent:
	district = p_district
	has_district = true
	return self
