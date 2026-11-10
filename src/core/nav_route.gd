class_name NavRoute
extends RefCounted
## A walking route (spec city-navigation / Routes over bridges): its nodes, its points relative to
## the start cell's centre, and its length in metres.

## Global nodes Vector4i(cell.x, cell.y, cell.z, node id).
var nodes: Array[Vector4i] = []
var points: PackedVector3Array = PackedVector3Array()
var length: float = 0.0
var start_cell: Vector3i


func is_empty() -> bool:
	return nodes.is_empty()


## Point at a distance along the route (clamped to its ends).
func point_at(distance: float) -> Vector3:
	if points.is_empty():
		return Vector3.ZERO
	var left := maxf(distance, 0.0)
	for i in range(1, points.size()):
		var step := points[i - 1].distance_to(points[i])
		if left <= step and step > 0.0:
			return points[i - 1].lerp(points[i], left / step)
		left -= step
	return points[points.size() - 1]


## Walking direction at a distance along the route (zero at a standstill).
func direction_at(distance: float) -> Vector3:
	var a := point_at(distance)
	var b := point_at(distance + 0.5)
	return (b - a).normalized() if a.distance_squared_to(b) > 0.0001 else Vector3.ZERO


func passes(cell: Vector3i, id: int) -> bool:
	return nodes.has(Vector4i(cell.x, cell.y, cell.z, id))
