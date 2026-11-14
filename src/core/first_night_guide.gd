class_name FirstNightGuide
extends RefCounted
## Prompts that teach the loop on the first night (spec first-night-guide): each step shows until
## its action has happened once, then the next one appears.

const STEPS: Array[Dictionary] = [
	{"id": "order_taken", "text": "Go to {patron} and press E at the door to take an order"},
	{"id": "delivered", "text": "Follow the arrow to the customer's door and press E to deliver"},
	{"id": "scene_answered", "text": "Answer the scene with the number keys"},
	{"id": "shop_opened", "text": "Press U to open the Couriers' Mutual shop"},
]

var done: Dictionary = {}


func mark(event: String) -> void:
	done[event] = true


## Text of the first step not done yet, or "" when the guide is finished.
func prompt(patron_name: String) -> String:
	for step in STEPS:
		if not done.has(step["id"]):
			return str(step["text"]).replace("{patron}", patron_name if not patron_name.is_empty() else "your patron")
	return ""


func is_finished() -> bool:
	return prompt("") == ""


func to_dict() -> Dictionary:
	return {"done": done.keys()}


func from_dict(data: Dictionary) -> void:
	done.clear()
	for id: String in data.get("done", []):
		done[id] = true
