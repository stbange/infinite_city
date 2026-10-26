class_name BlockInfo
extends RefCounted
## One floating block. Geometry is relative to its cell centre (see design D7).

var cell: Vector3i
## A BlockTypes.Kind value.
var kind: int
## Box size in metres.
var size: Vector3
## Box centre offset from the cell centre, in metres.
var offset: Vector3


func _init(p_cell: Vector3i, p_kind: int, p_size: Vector3, p_offset: Vector3) -> void:
	cell = p_cell
	kind = p_kind
	size = p_size
	offset = p_offset


## Box minimum corner relative to the cell centre.
func min_local() -> Vector3:
	return offset - size * 0.5


## Box maximum corner relative to the cell centre.
func max_local() -> Vector3:
	return offset + size * 0.5


func equals(other: BlockInfo) -> bool:
	return other != null and cell == other.cell and kind == other.kind \
			and size == other.size and offset == other.offset


func _to_string() -> String:
	return "BlockInfo(%s, %s, size=%s, offset=%s)" % [cell, BlockTypes.display_name(kind), size, offset]
