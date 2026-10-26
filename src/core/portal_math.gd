class_name PortalMath
extends RefCounted
## Pose mapping and crossing tests for doorway pairs (spec portal-traversal).
##
## A door is a Transform3D: origin at the bottom centre of the opening, +Y up, +Z pointing out
## of its front (the side you approach from). Passing through door A arrives at door B turned
## around, so what lies in front of A continues behind B and vice versa.

const DOOR_SIZE := Vector2(4.0, 6.0)
const _TURN := Basis(Vector3.UP, PI)


## Transform mapping world poses through `from_door` onto `to_door`.
static func pair(from_door: Transform3D, to_door: Transform3D) -> Transform3D:
	return to_door * Transform3D(_TURN, Vector3.ZERO) * from_door.affine_inverse()


static func map_pose(from_door: Transform3D, to_door: Transform3D, pose: Transform3D) -> Transform3D:
	return pair(from_door, to_door) * pose


## True when the segment from -> to crosses the door plane from front (z > 0) to back (z <= 0)
## at a point inside the opening (|x| <= w/2, 0 <= y <= h).
static func crossed(door: Transform3D, size: Vector2, from: Vector3, to: Vector3) -> bool:
	var inverse := door.affine_inverse()
	var a := inverse * from
	var b := inverse * to
	if not (a.z > 0.0 and b.z <= 0.0):
		return false
	var t := a.z / (a.z - b.z)
	var hit := a.lerp(b, t)
	return absf(hit.x) <= size.x * 0.5 and hit.y >= 0.0 and hit.y <= size.y


## (yaw, pitch) of a view basis built as Basis.from_euler(Vector3(pitch, yaw, 0)).
static func yaw_pitch_of(basis: Basis) -> Vector2:
	var forward := basis * Vector3(0, 0, -1)
	return Vector2(atan2(-forward.x, -forward.z), asin(clampf(forward.y, -1.0, 1.0)))
