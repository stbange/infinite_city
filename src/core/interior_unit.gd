class_name InteriorUnit
extends RefCounted
## One unit of a floor plan (a flat, shop, office...). Rects are in the x/z plane relative to the
## cell centre (Rect2.position.x = x, position.y = z).

var index: int
var rect: Rect2
## +1 when the unit's corridor lies on its high-z side, -1 when on its low-z side.
var front_sign: int
## Centre of the 1 m door in the front wall.
var door_x: float
## True when the unit's back side is the outer wall (it has windows).
var exterior: bool
## True for the unit holding the stair core.
var is_core: bool


func _init(p_index: int, p_rect: Rect2, p_front_sign: int, p_door_x: float, p_exterior: bool, p_is_core: bool) -> void:
	index = p_index
	rect = p_rect
	front_sign = p_front_sign
	door_x = p_door_x
	exterior = p_exterior
	is_core = p_is_core


func front_z() -> float:
	return rect.end.y if front_sign > 0 else rect.position.y


func back_z() -> float:
	return rect.position.y if front_sign > 0 else rect.end.y


## Depth from the front wall to the back wall.
func depth() -> float:
	return rect.size.y
