class_name StairFlight
extends RefCounted
## One straight flight of stairs: the walking line from `start` to `end` (relative to the cell
## centre) and its width.

var start: Vector3
var end: Vector3
var width: float


func _init(p_start: Vector3, p_end: Vector3, p_width: float) -> void:
	start = p_start
	end = p_end
	width = p_width


## Transform of a unit box whose top face is the walking surface (for collision).
func ramp_transform(thickness: float = 0.2) -> Transform3D:
	var along := end - start
	var length := along.length()
	var forward := along / length
	var side := Vector3.UP.cross(forward).normalized()
	if side.length_squared() < 0.5:
		side = Vector3.RIGHT
	var up := forward.cross(side).normalized()
	if up.y < 0.0:
		up = -up
		side = -side
	var basis := Basis(side * width, up * thickness, forward * length)
	var centre := (start + end) * 0.5 - up * thickness * 0.5
	return Transform3D(basis, centre)
