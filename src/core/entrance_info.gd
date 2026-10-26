class_name EntranceInfo
extends RefCounted
## Where a bridge meets a block: the floor and the face (axis and side).

var floor_index: int
var face_axis: int
var face_sign: int


func _init(p_floor: int, p_face_axis: int, p_face_sign: int) -> void:
	floor_index = p_floor
	face_axis = p_face_axis
	face_sign = p_face_sign


func matches(floor: int, axis: int, sign: int) -> bool:
	return floor_index == floor and face_axis == axis and face_sign == sign
