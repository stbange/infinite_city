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
## Distance falloff exponent of the OmniLight3D (lower reaches further, e.g. room lights).
var attenuation: float


func _init(p_id: int, p_position: Vector3, p_color: Color, p_energy: float, p_range: float,
		p_attenuation: float = 1.6) -> void:
	id = p_id
	position = p_position
	color = p_color
	energy = p_energy
	light_range = p_range
	attenuation = p_attenuation
