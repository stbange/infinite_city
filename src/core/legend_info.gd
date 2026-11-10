class_name LegendInfo
extends RefCounted
## A famous person of the city's history, tied to one event of their era.

var name: String
var born: int
## Year of death, or -1 if alive at the present.
var died: int = -1
var role: String
var faction_key: String
var event: HistoryEvent


func is_alive() -> bool:
	return died < 0
