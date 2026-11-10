class_name Reputation
extends RefCounted
## The courier's standing with each faction (spec courier-progression / Reputation).

const MUTUAL := "mutual"
const LEVELS: Array[String] = ["hostile", "wary", "neutral", "friendly", "trusted"]
## Lower bounds of wary, neutral, friendly and trusted.
const THRESHOLDS: Array[int] = [-50, -10, 25, 75]
const DELIVERY := 1
const STORY_DELIVERY := 3
const TOLL_PAID := 2
const RAN := -10
const CAUGHT := -5

var points: Dictionary = {}


func of(key: String) -> int:
	return int(points.get(key, 0))


func add(key: String, amount: int) -> void:
	points[key] = clampi(of(key) + amount, -100, 100)


func level(key: String) -> String:
	return level_of(of(key))


static func level_of(value: int) -> String:
	var index := 0
	for threshold in THRESHOLDS:
		if value >= threshold:
			index += 1
	return LEVELS[index]


func to_dict() -> Dictionary:
	return points.duplicate()


func from_dict(data: Dictionary) -> void:
	points.clear()
	for key: String in data:
		points[key] = int(data[key])
