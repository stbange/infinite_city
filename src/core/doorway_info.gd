class_name DoorwayInfo
extends RefCounted
## A magic doorway on a block face. `door` is relative to the cell centre: origin at the bottom
## centre of the opening, +Y up, +Z pointing outward (see PortalMath).

var cell: Vector3i
var block_kind: int
## Vector3.AXIS_X or Vector3.AXIS_Z: the axis the face is perpendicular to.
var face_axis: int
## +1 or -1: which side of the block along face_axis.
var face_sign: int
var door: Transform3D
## True when the doorway opens at the end of a bridge, standing on its deck.
var on_bridge: bool


func _init(p_cell: Vector3i, p_block_kind: int, p_face_axis: int, p_face_sign: int, p_door: Transform3D,
		p_on_bridge: bool) -> void:
	cell = p_cell
	block_kind = p_block_kind
	face_axis = p_face_axis
	face_sign = p_face_sign
	door = p_door
	on_bridge = p_on_bridge


func equals(other: DoorwayInfo) -> bool:
	return other != null and cell == other.cell and block_kind == other.block_kind \
			and face_axis == other.face_axis and face_sign == other.face_sign \
			and door == other.door and on_bridge == other.on_bridge


func _to_string() -> String:
	return "DoorwayInfo(%s, axis=%d, sign=%d, bridge=%s)" % [cell, face_axis, face_sign, on_bridge]
