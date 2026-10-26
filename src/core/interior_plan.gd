class_name InteriorPlan
extends RefCounted
## Floor plan of a block, identical for every floor (spec block-interiors). Coordinates are
## relative to the cell centre; rects lie in the x/z plane.

var block: BlockInfo
var floors: int
## Local y of floor 0's walking surface (the block's bottom).
var bottom: float
## The space inside the outer walls.
var inner: Rect2
var corridors: Array[Rect2] = []
## Footprint of the stair core.
var core: Rect2
var units: Array[InteriorUnit] = []
var entrances: Array[EntranceInfo] = []
## Bridge ends where a magic doorway stands instead of an entrance.
var magic_ends: Array[EntranceInfo] = []


func floor_y(k: int) -> float:
	return bottom + InteriorLayout.FLOOR_HEIGHT * k


func top() -> float:
	return floor_y(floors)


func has_entrance(floor: int, axis: int, sign: int) -> bool:
	for entrance in entrances:
		if entrance.matches(floor, axis, sign):
			return true
	return false


func is_magic_end(floor: int, axis: int, sign: int) -> bool:
	for end in magic_ends:
		if end.matches(floor, axis, sign):
			return true
	return false


## Floor index containing local height y (clamped to the block's floors).
func floor_at(y: float) -> int:
	return clampi(floori((y - bottom) / InteriorLayout.FLOOR_HEIGHT), 0, floors - 1)
