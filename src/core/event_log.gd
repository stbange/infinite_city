class_name EventLog
extends RefCounted
## Everything that changed in the world, in order (spec event-log): {minute, kind, …} records.

var events: Array[Dictionary] = []


func append(kind: String, minute: int, data: Dictionary = {}) -> Dictionary:
	var event := data.duplicate(true)
	event["kind"] = kind
	event["minute"] = minute
	events.append(event)
	return event


func size() -> int:
	return events.size()


func to_dict() -> Dictionary:
	return {"events": events.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	events.clear()
	for event: Dictionary in data.get("events", []):
		events.append(event.duplicate(true))
