class_name EraInfo
extends RefCounted
## An era of the city's history: years [start_year, end_year).

var kind: String
var name: String
var start_year: int
var end_year: int


func _init(p_kind: String, p_name: String, p_start: int, p_end: int) -> void:
	kind = p_kind
	name = p_name
	start_year = p_start
	end_year = p_end


func contains(year: int) -> bool:
	return year >= start_year and year < end_year
