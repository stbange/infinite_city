class_name SignInfo
extends RefCounted
## A neon sign mounted on a block face. `centre` is relative to the cell centre.

var cell: Vector3i
## Vector3.AXIS_X or Vector3.AXIS_Z.
var face_axis: int
## +1 or -1.
var face_sign: int
var centre: Vector3
## Width along the face (lateral) and height, in metres.
var size: Vector2
var color: Color
var flicker: bool
## 0..1, drives the glyph pattern in the shader.
var pattern_seed: float


func _init(p_cell: Vector3i, p_face_axis: int, p_face_sign: int, p_centre: Vector3, p_size: Vector2,
		p_color: Color, p_flicker: bool, p_pattern_seed: float) -> void:
	cell = p_cell
	face_axis = p_face_axis
	face_sign = p_face_sign
	centre = p_centre
	size = p_size
	color = p_color
	flicker = p_flicker
	pattern_seed = p_pattern_seed


func equals(other: SignInfo) -> bool:
	return other != null and cell == other.cell and face_axis == other.face_axis \
			and face_sign == other.face_sign and centre == other.centre and size == other.size \
			and color == other.color and flicker == other.flicker and pattern_seed == other.pattern_seed
