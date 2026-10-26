class_name LampInfo
extends RefCounted
## A lamp on a bridge edge. `position` is the light head, relative to the bridge's cell_a centre.

var cell_a: Vector3i
var position: Vector3
var color: Color


func _init(p_cell_a: Vector3i, p_position: Vector3, p_color: Color) -> void:
	cell_a = p_cell_a
	position = p_position
	color = p_color
