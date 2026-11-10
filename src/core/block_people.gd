class_name BlockPeople
extends RefCounted
## Everyone living in one housing block, in parallel arrays (spec relations).

var ids: Array[PersonId] = []
var ages := PackedInt32Array()
var floors := PackedInt32Array()
var units := PackedInt32Array()
var slots := PackedInt32Array()
## Family line of the person's household, -1 for flatmates.
var lines := PackedInt32Array()
var types := PackedStringArray()
## Faction key of each person's membership, or "".
var memberships := PackedStringArray()
var _index: Dictionary = {}   # local id -> index


func add(id: PersonId, age: int, floor_index: int, unit: int, slot: int, line: int, type: String,
		membership: String = "") -> void:
	memberships.append(membership)
	_index[id.local] = ids.size()
	ids.append(id)
	ages.append(age)
	floors.append(floor_index)
	units.append(unit)
	slots.append(slot)
	lines.append(line)
	types.append(type)


func index_of(id: PersonId) -> int:
	return _index.get(id.local, -1)


func size() -> int:
	return ids.size()
