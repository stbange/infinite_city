class_name SpawnPoint
extends RefCounted
## Where and how the camera starts.

var cell: Vector3i
## Position inside the cell, metres from its minimum corner.
var offset: Vector3
var yaw: float
var pitch: float
## Centre of the shaft being looked at, absolute metres (only meaningful near the origin).
var shaft_center: Vector3


func _init(p_cell: Vector3i, p_offset: Vector3, p_yaw: float, p_pitch: float, p_shaft_center: Vector3) -> void:
	cell = p_cell
	offset = p_offset
	yaw = p_yaw
	pitch = p_pitch
	shaft_center = p_shaft_center


func absolute_metres(cell_size: Vector3) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	result.resize(3)
	for axis in 3:
		result[axis] = float(cell[axis]) * cell_size[axis] + offset[axis]
	return result
