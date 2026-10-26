class_name BridgeInfo
extends RefCounted
## A pedestrian bridge between two neighbouring blocks.
## Points are on the deck's centre line at walking height, relative to cell_a's centre.

## The lower-coordinate cell along the bridge axis (the owner).
var cell_a: Vector3i
var cell_b: Vector3i
## Vector3.AXIS_X or Vector3.AXIS_Z.
var axis: int
## Where the deck leaves block A's facing side, relative to cell_a's centre.
var start: Vector3
## Where the deck reaches block B's facing side, relative to cell_a's centre.
var end: Vector3
var width: float


func _init(p_cell_a: Vector3i, p_cell_b: Vector3i, p_axis: int, p_start: Vector3, p_end: Vector3, p_width: float) -> void:
	cell_a = p_cell_a
	cell_b = p_cell_b
	axis = p_axis
	start = p_start
	end = p_end
	width = p_width


func length() -> float:
	return start.distance_to(end)


func equals(other: BridgeInfo) -> bool:
	return other != null and cell_a == other.cell_a and cell_b == other.cell_b and axis == other.axis \
			and start == other.start and end == other.end and width == other.width


func _to_string() -> String:
	return "BridgeInfo(%s -> %s, axis=%d, %s..%s)" % [cell_a, cell_b, axis, start, end]
