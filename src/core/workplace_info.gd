class_name WorkplaceInfo
extends RefCounted
## A workplace: a non-core unit of a block that is not housing (spec workplaces).

var id: PersonId
var cell: Vector3i
var floor_index: int
var unit: int
var kind: int
## What the business is (noodle bar, office, ward …).
var trade: String
var is_food: bool = false
var slots: int = 0
## Opening hours in minutes of the day (closes may exceed 24:00 for overnight hours).
var opens: int = 0
var closes: int = 0
var name: String = ""


func key() -> String:
	return id.key()


func is_open_at(minute_of_day: int) -> bool:
	if closes - opens >= 24 * 60:
		return true
	return minute_of_day >= opens and minute_of_day < closes
