class_name WalkModel
extends RefCounted
## First-person walking rules (spec on-foot-movement / Walking, Sprinting, Jumping and gravity).
## Pure velocity update; the scene node applies it with move_and_slide().

const EYE_HEIGHT := 1.65

var walk_speed: float = 4.5
var sprint_speed: float = 8.0
var jump_speed: float = 4.6
var gravity: float = 9.81
var ground_acceleration: float = 60.0
var air_acceleration: float = 10.0


## New velocity. `input`: x = right, y = forward, each in [-1, 1]; `yaw` turns around +Y.
func step(velocity: Vector3, yaw: float, input: Vector2, sprint: bool, jump: bool, on_floor: bool,
		delta: float) -> Vector3:
	var basis := Basis(Vector3.UP, yaw)
	var direction := basis * Vector3(input.x, 0.0, -input.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	var target := direction * (sprint_speed if sprint else walk_speed)
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var acceleration := ground_acceleration if on_floor else air_acceleration
	horizontal = horizontal.move_toward(target, acceleration * delta)
	var vertical := velocity.y
	if on_floor:
		vertical = jump_speed if jump else 0.0
	else:
		vertical -= gravity * delta
	return Vector3(horizontal.x, vertical, horizontal.z)
