class_name ChunkData
extends RefCounted
## Everything generated for one chunk: its blocks and the bridges it owns.

var chunk: Vector3i
var blocks: Array[BlockInfo] = []
## Bridges whose cell_a lies in this chunk.
var bridges: Array[BridgeInfo] = []


func _init(p_chunk: Vector3i) -> void:
	chunk = p_chunk


func is_empty() -> bool:
	return blocks.is_empty() and bridges.is_empty()
