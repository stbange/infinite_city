class_name FloatingOrigin
extends RefCounted
## Scene positions are relative to an integer origin chunk (spec floating-origin).
## Only differences of integer coordinates are converted to float, so precision does not
## depend on how far from the world origin the player is.

var origin_chunk: Vector3i = Vector3i.ZERO
var cell_size: Vector3
var chunk_cells: int
## Rebase when the camera is further than this from the scene origin on any axis (metres).
var threshold: float = 512.0


func _init(p_cell_size: Vector3 = Vector3(64, 64, 64), p_chunk_cells: int = 4) -> void:
	cell_size = p_cell_size
	chunk_cells = p_chunk_cells


static func for_config(config: CityConfig) -> FloatingOrigin:
	return FloatingOrigin.new(config.cell_size, config.chunk_cells)


func chunk_size() -> Vector3:
	return cell_size * chunk_cells


## Absolute cell at the scene origin.
func origin_cell() -> Vector3i:
	return origin_chunk * chunk_cells


## Scene position of a cell's minimum corner.
func scene_position_of_cell(cell: Vector3i) -> Vector3:
	return Vector3(cell - origin_cell()) * cell_size


func scene_position_of_cell_center(cell: Vector3i) -> Vector3:
	return (Vector3(cell - origin_cell()) + Vector3(0.5, 0.5, 0.5)) * cell_size


## Scene position of a chunk's minimum corner.
func scene_position_of_chunk(chunk: Vector3i) -> Vector3:
	return Vector3(chunk - origin_chunk) * chunk_size()


func absolute_cell_of(scene_position: Vector3) -> Vector3i:
	return origin_cell() + Vector3i((scene_position / cell_size).floor())


func absolute_chunk_of(scene_position: Vector3) -> Vector3i:
	return origin_chunk + Vector3i((scene_position / chunk_size()).floor())


## Position inside the absolute cell, each component in [0, cell size).
func offset_in_cell(scene_position: Vector3) -> Vector3:
	return scene_position - (scene_position / cell_size).floor() * cell_size


## Chunks to move the origin by so the camera is near it again; ZERO if no rebase is needed.
func rebase_delta(camera_position: Vector3) -> Vector3i:
	if absf(camera_position.x) <= threshold and absf(camera_position.y) <= threshold \
			and absf(camera_position.z) <= threshold:
		return Vector3i.ZERO
	return Vector3i((camera_position / chunk_size()).floor())


## Moves the origin; returns the scene-space shift to subtract from every world position.
func apply_rebase(delta: Vector3i) -> Vector3:
	origin_chunk += delta
	return Vector3(delta) * chunk_size()


## Absolute position in metres, per axis, with 64-bit precision.
func absolute_metres(scene_position: Vector3) -> PackedFloat64Array:
	var size := chunk_size()
	var result := PackedFloat64Array()
	result.resize(3)
	for axis in 3:
		result[axis] = float(origin_chunk[axis]) * size[axis] + scene_position[axis]
	return result


## Moves the origin to the chunk containing an absolute position; returns its scene position.
func place_origin_at(absolute: PackedFloat64Array) -> Vector3:
	var size := chunk_size()
	var local := Vector3()
	for axis in 3:
		var chunk_index := floori(absolute[axis] / size[axis])
		origin_chunk[axis] = chunk_index
		local[axis] = absolute[axis] - float(chunk_index) * size[axis]
	return local
