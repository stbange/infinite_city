class_name Household
extends RefCounted
## The household of a flat (spec residents): vacant, single, couple, family or flatmates.

var type: String = "vacant"
## Ages of the members, by household slot.
var ages := PackedInt32Array()
var culture: int = 0


func is_vacant() -> bool:
	return ages.is_empty()
