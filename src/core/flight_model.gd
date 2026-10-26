class_name FlightModel
extends RefCounted
## Six-degree-of-freedom spectator flight (spec free-flight). Pure math, no input handling.

const MAX_PITCH := deg_to_rad(89.0)

## Metres per second without boost.
var cruise_speed: float = 40.0
var boost_factor: float = 6.0
## Radians of rotation per pixel of mouse motion.
var mouse_sensitivity: float = 0.0025


## View orientation for a yaw (around +Y) and pitch (positive looks up).
static func view_basis(yaw: float, pitch: float) -> Basis:
	return Basis.from_euler(Vector3(pitch, yaw, 0.0))


## Velocity for an input vector in view space: x = right, y = up (world vertical),
## -z = forward (along the full view direction, including pitch).
func velocity(yaw: float, pitch: float, input: Vector3, boost: bool) -> Vector3:
	var forward := view_basis(yaw, pitch) * Vector3(0, 0, -1)
	var right := Basis(Vector3.UP, yaw) * Vector3(1, 0, 0)
	var direction := right * input.x + Vector3.UP * input.y + forward * -input.z
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	return direction * cruise_speed * (boost_factor if boost else 1.0)


## New (yaw, pitch) after mouse motion in pixels; moving the mouse up looks up.
func apply_mouse(yaw: float, pitch: float, motion: Vector2) -> Vector2:
	var new_yaw := yaw - motion.x * mouse_sensitivity
	var new_pitch := clampf(pitch - motion.y * mouse_sensitivity, -MAX_PITCH, MAX_PITCH)
	return Vector2(new_yaw, new_pitch)
