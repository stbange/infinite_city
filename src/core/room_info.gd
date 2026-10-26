class_name RoomInfo
extends RefCounted
## A room of a floor: its footprint (x/z plane, relative to the cell centre), name and light.

var name: String
var rect: Rect2
## Index of the unit the room belongs to (-1 for corridors).
var unit_index: int
## Position of the room's light (relative to the cell centre).
var light: Vector3
var light_color: Color
var light_energy: float


func _init(p_name: String, p_rect: Rect2, p_unit_index: int, p_light: Vector3, p_color: Color, p_energy: float) -> void:
	name = p_name
	rect = p_rect
	unit_index = p_unit_index
	light = p_light
	light_color = p_color
	light_energy = p_energy
