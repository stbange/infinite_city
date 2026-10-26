class_name FallGuard
extends RefCounted
## Safety net for the bottomless city (spec on-foot-movement / Fall safety net): remembers where
## the player last stood steadily and asks for a reset after too long in the air.

var limit_seconds: float = 4.0
## Ground contact must last this long before it counts as a safe place.
var settle_seconds: float = 0.3

var _safe := Vector3.ZERO
var _has_safe: bool = false
var _air_time: float = 0.0
var _ground_time: float = 0.0


## Feeds one frame; returns true when the player must be put back at reset_point().
func update(on_floor: bool, position: Vector3, delta: float) -> bool:
	if on_floor:
		_air_time = 0.0
		_ground_time += delta
		if _ground_time >= settle_seconds:
			_safe = position
			_has_safe = true
		return false
	_ground_time = 0.0
	_air_time += delta
	if _air_time > limit_seconds and _has_safe:
		_air_time = 0.0
		return true
	return false


func reset_point() -> Vector3:
	return _safe


func has_safe_point() -> bool:
	return _has_safe


## Moves the remembered place along with a floating-origin rebase.
func shift(offset: Vector3) -> void:
	_safe += offset
