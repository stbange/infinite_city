class_name Heat
extends RefCounted
## How wanted the courier is per gang (spec gang-turf / Tolls and heat); halves every HALF_LIFE
## game minutes.

const HALF_LIFE := 120.0

var _values: Dictionary = {}   # gang key -> [value, minute]


func value_at(key: String, minute: int) -> float:
	if not _values.has(key):
		return 0.0
	var entry: Array = _values[key]
	return float(entry[0]) * pow(0.5, maxf(0.0, minute - int(entry[1])) / HALF_LIFE)


func add(key: String, amount: float, minute: int) -> void:
	_values[key] = [value_at(key, minute) + amount, minute]


func to_dict() -> Dictionary:
	return _values.duplicate(true)


func from_dict(data: Dictionary) -> void:
	_values.clear()
	for key: String in data:
		var entry: Array = data[key]
		_values[key] = [float(entry[0]), int(entry[1])]
