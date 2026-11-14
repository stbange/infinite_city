class_name StoryState
extends RefCounted
## Progress through a plot template (spec story-director): the cast, flags, finished beats (with
## the delivery count when each finished), the active beat and what it waits for.

var template_id: String = ""
var act: int = 1
var cast: Dictionary = {}     # role -> Dictionary (see StoryDirector.cast)
var flags: Dictionary = {}    # flag -> true
var done: Dictionary = {}     # beat id -> deliveries when it finished
var active: String = ""
## Scene open for the active beat, or "".
var scene: String = ""
## Role whose story job must be delivered for the active beat, or "".
var job_role: String = ""
## Role the courier must meet in person for the active beat, or "".
var meet_role: String = ""


func is_cast() -> bool:
	return not cast.is_empty()


func to_dict() -> Dictionary:
	return {"template": template_id, "act": act, "cast": cast.duplicate(true), "flags": flags.keys(),
		"done": done.duplicate(), "active": active, "scene": scene, "job_role": job_role, "meet_role": meet_role}


func from_dict(data: Dictionary) -> void:
	template_id = data.get("template", "")
	act = int(data.get("act", 1))
	cast = _whole_numbers(data.get("cast", {}))
	flags.clear()
	for flag: String in data.get("flags", []):
		flags[flag] = true
	done.clear()
	var finished: Dictionary = data.get("done", {})
	for beat: String in finished:
		done[beat] = int(finished[beat])
	active = data.get("active", "")
	scene = data.get("scene", "")
	job_role = data.get("job_role", "")
	meet_role = data.get("meet_role", "")


## JSON brings numbers back as floats; whole ones become ints again (ages, cells, floors).
static func _whole_numbers(value: Variant) -> Variant:
	if value is float and float(value) == floorf(value):
		return int(value)
	if value is Array:
		var list: Array = []
		for item: Variant in value:
			list.append(_whole_numbers(item))
		return list
	if value is Dictionary:
		var result := {}
		for key: Variant in value:
			result[key] = _whole_numbers(value[key])
		return result
	return value
