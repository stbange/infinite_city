class_name StreamingPlanner
extends RefCounted
## Decides which chunks should be loaded around a focus chunk (spec world-streaming).
## Pure logic: works on chunk coordinates only.

## Horizontal radius of the streaming ellipsoid, in chunks.
var radius_h: int
## Vertical radius of the streaming ellipsoid, in chunks.
var radius_v: int
## Highest chunk y that can contain anything (chunks above are never loaded).
var top_chunk_y: int
## Maximum chunks generated per update.
var budget: int = 4

var _offsets: Array[Vector3i] = []


func _init(p_radius_h: int = 4, p_radius_v: int = 3, p_top_chunk_y: int = 1) -> void:
	radius_h = p_radius_h
	radius_v = p_radius_v
	top_chunk_y = p_top_chunk_y
	_offsets = _sorted_offsets()


static func for_config(config: CityConfig, p_radius_h: int = 4, p_radius_v: int = 3) -> StreamingPlanner:
	var top := IntMath.floor_div(config.roof_layer + config.sky_layers, config.chunk_cells)
	return StreamingPlanner.new(p_radius_h, p_radius_v, top)


## (dx/H)^2 + (dy/V)^2 + (dz/H)^2 for the given radii; <= 1 means inside.
func region_distance(offset: Vector3i, rh: int = -1, rv: int = -1) -> float:
	var h := float(radius_h if rh < 0 else rh)
	var v := float(radius_v if rv < 0 else rv)
	return (offset.x * offset.x) / (h * h) + (offset.y * offset.y) / (v * v) + (offset.z * offset.z) / (h * h)


## Every chunk of the region, nearest first.
func load_order(focus: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for offset in _offsets:
		var chunk := focus + offset
		if chunk.y <= top_chunk_y:
			result.append(chunk)
	return result


## Up to `max_count` chunks of the region that are not loaded yet, nearest first.
func next_loads(focus: Vector3i, loaded: Dictionary, max_count: int = -1) -> Array[Vector3i]:
	var limit := budget if max_count < 0 else max_count
	var result: Array[Vector3i] = []
	for offset in _offsets:
		if result.size() >= limit:
			break
		var chunk := focus + offset
		if chunk.y <= top_chunk_y and not loaded.has(chunk):
			result.append(chunk)
	return result


## Loaded chunks outside the region enlarged by one chunk on every axis.
func to_unload(focus: Vector3i, loaded: Dictionary) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for chunk: Vector3i in loaded:
		if region_distance(chunk - focus, radius_h + 1, radius_v + 1) > 1.0:
			result.append(chunk)
	return result


func _sorted_offsets() -> Array[Vector3i]:
	var offsets: Array[Vector3i] = []
	for dy in range(-radius_v, radius_v + 1):
		for dx in range(-radius_h, radius_h + 1):
			for dz in range(-radius_h, radius_h + 1):
				var offset := Vector3i(dx, dy, dz)
				if region_distance(offset) <= 1.0:
					offsets.append(offset)
	offsets.sort_custom(_closer)
	return offsets


func _closer(a: Vector3i, b: Vector3i) -> bool:
	var da := region_distance(a)
	var db := region_distance(b)
	if da != db:
		return da < db
	if absi(a.y) != absi(b.y):
		return absi(a.y) < absi(b.y)
	if a.y != b.y:
		return a.y < b.y
	if a.x != b.x:
		return a.x < b.x
	return a.z < b.z
