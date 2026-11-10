class_name RoutineStep
extends RefCounted
## One segment of a person's day (spec routines): what they do from `start` to `end` (absolute game
## minutes) and where — the place they are at, or walk to from `from`.

var activity: String
var place: NavPlace
var from: NavPlace
var start: int
var end: int
var walking: bool = false


func _init(p_activity: String, p_place: NavPlace, p_start: int, p_end: int, p_from: NavPlace = null) -> void:
	activity = p_activity
	place = p_place
	start = p_start
	end = p_end
	from = p_from
	walking = p_from != null


func contains(minute: int) -> bool:
	return minute >= start and minute < end


func equals(other: RoutineStep) -> bool:
	return other != null and activity == other.activity and place.equals(other.place) and start == other.start \
			and end == other.end and walking == other.walking and (from == null or from.equals(other.from))


func _to_string() -> String:
	return "RoutineStep(%s %d-%d %s)" % [activity, start, end, place]
