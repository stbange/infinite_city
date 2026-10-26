class_name LightAnchor
extends RefCounted
## A place where a real light source may be put (a sign, a lamp, a room light).

## Stable identity across frames and rebases.
var id: int
## Scene position.
var position: Vector3
var color: Color
var energy: float
var light_range: float


func _init(p_id: int, p_position: Vector3, p_color: Color, p_energy: float, p_range: float) -> void:
	id = p_id
	position = p_position
	color = p_color
	energy = p_energy
	light_range = p_range
