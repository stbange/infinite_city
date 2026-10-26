class_name CityLayout
extends RefCounted
## The deterministic city generator: answers "what is in cell (x, y, z)?" for any cell.

var config: CityConfig


func _init(city_config: CityConfig) -> void:
	config = city_config


# --- Lattice -----------------------------------------------------------------------------

## Axis-aligned bounds of a cell in metres. Absolute floats: use near the origin only.
func cell_bounds(cell: Vector3i) -> AABB:
	return AABB(Vector3(cell) * config.cell_size, config.cell_size)


func cell_center(cell: Vector3i) -> Vector3:
	return (Vector3(cell) + Vector3(0.5, 0.5, 0.5)) * config.cell_size


func cell_of_position(position: Vector3) -> Vector3i:
	return Vector3i((position / config.cell_size).floor())


func chunk_of(cell: Vector3i) -> Vector3i:
	return IntMath.floor_div_v3i(cell, config.chunk_cells)


func chunk_origin_cell(chunk: Vector3i) -> Vector3i:
	return chunk * config.chunk_cells


# --- Districts ---------------------------------------------------------------------------

const SALT_OCCUPANCY := 1
const SALT_SHAFT := 2
const SALT_CANYON_X := 3
const SALT_CANYON_Z := 4
const SALT_PLAZA := 5
const SALT_BLOCK := 6
const SALT_SERVICES := 7
const SALT_BRIDGE := 8

const _CACHE_LIMIT := 4096

var _shaft_cache: Dictionary = {}      # Vector2i(dx, dz) -> Rect2i (x, z); empty when none
var _canyon_x_cache: Dictionary = {}   # Vector2i(dy, dz) -> Rect2i (z, y); empty when none
var _canyon_z_cache: Dictionary = {}   # Vector2i(dx, dy) -> Rect2i (x, y); empty when none
var _plaza_cache: Dictionary = {}      # Vector3i district -> AABB-like [origin, size]; [] when none


## District containing a cell. The roof layer is the top layer of district row -1.
func district_of(cell: Vector3i) -> Vector3i:
	var d := config.district_size
	return Vector3i(IntMath.floor_div(cell.x, d),
			IntMath.floor_div(cell.y - config.roof_layer - 1, d),
			IntMath.floor_div(cell.z, d))


## Minimum-corner cell of a district.
func district_origin_cell(district: Vector3i) -> Vector3i:
	var d := config.district_size
	return Vector3i(district.x * d, district.y * d + config.roof_layer + 1, district.z * d)


## Cell position inside its district, each component in [0, district_size).
func local_in_district(cell: Vector3i) -> Vector3i:
	var d := config.district_size
	return Vector3i(posmod(cell.x, d), posmod(cell.y - config.roof_layer - 1, d), posmod(cell.z, d))


# --- Canyons -----------------------------------------------------------------------------

func _remember(cache: Dictionary, key: Variant, value: Variant) -> void:
	if cache.size() >= _CACHE_LIMIT:
		cache.clear()
	cache[key] = value


## Shaft footprint inside district column (dx, dz) in local (x, z) cells; size 0 when none.
func shaft_rect(dx: int, dz: int) -> Rect2i:
	var key := Vector2i(dx, dz)
	var cached: Variant = _shaft_cache.get(key)
	if cached != null:
		return cached
	var rect := Rect2i()
	var rng := CellRandom.new(DetHash.hash2(config.world_seed, SALT_SHAFT, dx, dz))
	if rng.next_float() < config.shaft_chance:
		var w := rng.range_int(2, 3)
		rect = Rect2i(rng.range_int(0, config.district_size - w), rng.range_int(0, config.district_size - w), w, w)
	_remember(_shaft_cache, key, rect)
	return rect


func has_shaft(dx: int, dz: int) -> bool:
	return shaft_rect(dx, dz).has_area()


## Cross-section of the X-running canyon of district row (dy, dz) in local (z, y) cells.
func canyon_x_rect(dy: int, dz: int) -> Rect2i:
	var key := Vector2i(dy, dz)
	var cached: Variant = _canyon_x_cache.get(key)
	if cached != null:
		return cached
	var rect := _canyon_rect(DetHash.hash2(config.world_seed, SALT_CANYON_X, dy, dz), dy)
	_remember(_canyon_x_cache, key, rect)
	return rect


## Cross-section of the Z-running canyon of district row (dx, dy) in local (x, y) cells.
func canyon_z_rect(dx: int, dy: int) -> Rect2i:
	var key := Vector2i(dx, dy)
	var cached: Variant = _canyon_z_cache.get(key)
	if cached != null:
		return cached
	var rect := _canyon_rect(DetHash.hash2(config.world_seed, SALT_CANYON_Z, dx, dy), dy)
	_remember(_canyon_z_cache, key, rect)
	return rect


func _canyon_rect(hash_value: int, dy: int) -> Rect2i:
	if dy > -1:
		return Rect2i()  # horizontal canyons exist only at or below the roof
	var rng := CellRandom.new(hash_value)
	if rng.next_float() >= config.canyon_chance:
		return Rect2i()
	var w := rng.range_int(2, 3)
	var h := rng.range_int(1, 2)
	return Rect2i(rng.range_int(0, config.district_size - w), rng.range_int(0, config.district_size - h), w, h)


## Plaza of a district as [origin: Vector3i, size: Vector3i] in local cells; [] when none.
func plaza_box(district: Vector3i) -> Array:
	var cached: Variant = _plaza_cache.get(district)
	if cached != null:
		return cached
	var box: Array = []
	if district.y <= -1:
		var rng := CellRandom.new(DetHash.hash3(config.world_seed, SALT_PLAZA, district.x, district.y, district.z))
		if rng.next_float() < config.plaza_chance:
			var size := Vector3i(rng.range_int(1, 3), rng.range_int(1, 3), rng.range_int(1, 3))
			var d := config.district_size
			var origin := Vector3i(rng.range_int(0, d - size.x), rng.range_int(0, d - size.y), rng.range_int(0, d - size.z))
			box = [origin, size]
	_remember(_plaza_cache, district, box)
	return box


func has_plaza(district: Vector3i) -> bool:
	return not plaza_box(district).is_empty()


func in_shaft(cell: Vector3i) -> bool:
	var d := config.district_size
	return shaft_rect(IntMath.floor_div(cell.x, d), IntMath.floor_div(cell.z, d)) \
			.has_point(Vector2i(posmod(cell.x, d), posmod(cell.z, d)))


func in_canyon_x(cell: Vector3i) -> bool:
	var district := district_of(cell)
	var local := local_in_district(cell)
	return canyon_x_rect(district.y, district.z).has_point(Vector2i(local.z, local.y))


func in_canyon_z(cell: Vector3i) -> bool:
	var district := district_of(cell)
	var local := local_in_district(cell)
	return canyon_z_rect(district.x, district.y).has_point(Vector2i(local.x, local.y))


func in_plaza(cell: Vector3i) -> bool:
	var box := plaza_box(district_of(cell))
	if box.is_empty():
		return false
	var local := local_in_district(cell)
	var origin: Vector3i = box[0]
	var size: Vector3i = box[1]
	return local.x >= origin.x and local.x < origin.x + size.x \
			and local.y >= origin.y and local.y < origin.y + size.y \
			and local.z >= origin.z and local.z < origin.z + size.z


## True when the cell lies in a shaft, a horizontal canyon or a plaza.
func is_carved(cell: Vector3i) -> bool:
	return in_shaft(cell) or in_canyon_x(cell) or in_canyon_z(cell) or in_plaza(cell)


# --- Occupancy ---------------------------------------------------------------------------

## Probability that an uncarved cell on this layer holds a block.
func layer_density(y: int) -> float:
	var y_rel := y - config.roof_layer
	if y_rel == 0:
		return config.roof_density
	if y_rel < 0:
		return config.base_density
	if y_rel > config.sky_layers:
		return 0.0
	return config.sky_density * float(config.sky_layers - y_rel + 1) / float(config.sky_layers)


## True when the cell holds a block.
func is_solid(cell: Vector3i) -> bool:
	if cell.y - config.roof_layer > config.sky_layers:
		return false
	if is_carved(cell):
		return false
	return DetHash.u01(DetHash.hash_cell(config.world_seed, SALT_OCCUPANCY, cell)) < layer_density(cell.y)


# --- Blocks and zoning -------------------------------------------------------------------

const _SERVICE_ATTEMPTS := 64

var _plan_cache: Dictionary = {}   # Vector3i district -> Dictionary(Vector3i cell -> kind)


## Height of one floor; block bottoms/tops and bridge decks lie on this world-wide grid.
const FLOOR_HEIGHT := 4.0


func min_floors() -> int:
	return ceili(config.cell_size.y * config.block_fill_min / FLOOR_HEIGHT)


func max_floors() -> int:
	var tallest := minf(config.cell_size.y * config.block_fill_max, config.cell_size.y - config.min_street_gap)
	return floori(tallest / FLOOR_HEIGHT)


## The block in a cell, or null for open air.
func block_at(cell: Vector3i) -> BlockInfo:
	if not is_solid(cell):
		return null
	var rng := CellRandom.new(DetHash.hash_cell(config.world_seed, SALT_BLOCK, cell))
	var size := Vector3()
	var offset := Vector3()
	for axis in 3:
		var cell_len: float = config.cell_size[axis]
		if axis == Vector3.AXIS_Y:
			# Whole floors on the world-wide floor grid (spec city-layout / Floor grid).
			var floors := rng.range_int(min_floors(), max_floors())
			var height := floors * FLOOR_HEIGHT
			var limit := cell_len * 0.5 - config.min_street_gap * 0.5
			var core := FLOOR_HEIGHT  # every block covers the cell centre +- one floor
			var b_lo := ceilf(maxf(-limit, core - height) / FLOOR_HEIGHT) * FLOOR_HEIGHT
			var b_hi := floorf(minf(-core, limit - height) / FLOOR_HEIGHT) * FLOOR_HEIGHT
			var steps := maxi(0, roundi((b_hi - b_lo) / FLOOR_HEIGHT))
			var bottom := b_lo + FLOOR_HEIGHT * rng.range_int(0, steps)
			size.y = height
			offset.y = bottom + height * 0.5
			continue
		var fill := rng.range_float(config.block_fill_min, config.block_fill_max)
		var length := minf(cell_len * fill, cell_len - config.min_street_gap)
		var free := cell_len - length - config.min_street_gap
		size[axis] = length
		offset[axis] = rng.range_float(-free * 0.5, free * 0.5) if free > 0.0 else 0.0
	var general := BlockTypes.GENERAL[rng.pick_weighted(
			BlockTypes.general_weights(BlockTypes.depth_band(cell.y - config.roof_layer)))]
	var kind: int = district_plan(district_of(cell)).get(cell, general)
	return BlockInfo.new(cell, kind, size, offset)


## Function of the block in a cell, or BlockTypes.NONE for open air.
func block_kind_at(cell: Vector3i) -> int:
	var block := block_at(cell)
	return BlockTypes.NONE if block == null else block.kind


## Absolute bounds of a block. Absolute floats: use near the origin only.
func block_aabb(block: BlockInfo) -> AABB:
	return AABB(cell_center(block.cell) + block.min_local(), block.size)


## Essential-service placement of a district: Dictionary(Vector3i cell -> kind).
## Empty for districts in the sky (district row 0 and above).
func district_plan(district: Vector3i) -> Dictionary:
	var cached: Variant = _plan_cache.get(district)
	if cached != null:
		return cached
	var plan := {}
	if district.y <= -1:
		var origin := district_origin_cell(district)
		var d := config.district_size
		var rng := CellRandom.new(DetHash.hash3(config.world_seed, SALT_SERVICES, district.x, district.y, district.z))
		for service in BlockTypes.SERVICES:
			var placed := false
			for attempt in _SERVICE_ATTEMPTS:
				var cell := origin + Vector3i(rng.next_int(d), rng.next_int(d), rng.next_int(d))
				if not plan.has(cell) and is_solid(cell):
					plan[cell] = service
					placed = true
					break
			if not placed:
				_place_by_scan(plan, origin, service)
	_remember(_plan_cache, district, plan)
	return plan


## Fallback for very sparse districts: first free solid cell in x -> y -> z order.
func _place_by_scan(plan: Dictionary, origin: Vector3i, service: int) -> void:
	var d := config.district_size
	for lz in d:
		for ly in d:
			for lx in d:
				var cell := origin + Vector3i(lx, ly, lz)
				if not plan.has(cell) and is_solid(cell):
					plan[cell] = service
					return


# --- Bridges -----------------------------------------------------------------------------

const BRIDGE_AXES: Array[int] = [Vector3.AXIS_X, Vector3.AXIS_Z]


static func axis_unit(axis: int) -> Vector3i:
	match axis:
		Vector3.AXIS_X:
			return Vector3i(1, 0, 0)
		Vector3.AXIS_Y:
			return Vector3i(0, 1, 0)
		_:
			return Vector3i(0, 0, 1)


## The bridge from cell_a to its +axis neighbour (axis X or Z), or null.
func bridge_between(cell_a: Vector3i, axis: int) -> BridgeInfo:
	var rng := _bridge_rng(cell_a, axis)
	if rng == null:
		return null
	var a := block_at(cell_a)
	if a == null:
		return null
	var b := block_at(cell_a + axis_unit(axis))
	if b == null:
		return null
	return _shape_bridge(rng, a, b, axis)


## All bridges touching the block in a cell (from either end).
func bridges_of(cell: Vector3i) -> Array[BridgeInfo]:
	var result: Array[BridgeInfo] = []
	if not is_solid(cell):
		return result
	for axis in BRIDGE_AXES:
		for owner_cell: Vector3i in [cell, cell - axis_unit(axis)]:
			var bridge := bridge_between(owner_cell, axis)
			if bridge != null:
				result.append(bridge)
	return result


## Random stream for the bridge slot, or null when the slot has no bridge.
func _bridge_rng(cell_a: Vector3i, axis: int) -> CellRandom:
	var rng := CellRandom.new(DetHash.hash4(config.world_seed, SALT_BRIDGE, cell_a.x, cell_a.y, cell_a.z, axis))
	return rng if rng.next_float() < config.bridge_chance else null


## The deck runs along the line through both cell centres (lateral 0) at a floor-grid level
## with at least one floor of both blocks above it (spec city-bridges / Bridge geometry) and,
## so that doorways at its end keep a margin, never on either block's lowest floor.
func _shape_bridge(rng: CellRandom, a: BlockInfo, b: BlockInfo, axis: int) -> BridgeInfo:
	var lowest := maxf(a.min_local().y, b.min_local().y) + FLOOR_HEIGHT
	var highest := minf(a.max_local().y, b.max_local().y) - FLOOR_HEIGHT
	var levels := maxi(0, roundi((highest - lowest) / FLOOR_HEIGHT))
	var start := Vector3()
	start[axis] = a.max_local()[axis]
	start.y = lowest + FLOOR_HEIGHT * rng.range_int(0, levels)
	var end := start
	end[axis] = config.cell_size[axis] + b.min_local()[axis]
	return BridgeInfo.new(a.cell, b.cell, axis, start, end, config.bridge_width)


# --- Chunks ------------------------------------------------------------------------------

## Generates all blocks of a chunk and the bridges it owns.
func generate_chunk(chunk: Vector3i) -> ChunkData:
	var data := ChunkData.new(chunk)
	var origin := chunk_origin_cell(chunk)
	if origin.y - config.roof_layer > config.sky_layers:
		return data
	var n := config.chunk_cells
	var known := {}  # Vector3i -> BlockInfo for solid cells of this chunk
	for z in n:
		for y in n:
			for x in n:
				var block := block_at(origin + Vector3i(x, y, z))
				if block != null:
					data.blocks.append(block)
					known[block.cell] = block
	var chunk_end := origin + Vector3i(n, n, n)
	for a in data.blocks:
		for axis in BRIDGE_AXES:
			var rng := _bridge_rng(a.cell, axis)
			if rng == null:
				continue
			var cell_b := a.cell + axis_unit(axis)
			var inside := cell_b.x < chunk_end.x and cell_b.z < chunk_end.z
			var b: BlockInfo = known.get(cell_b) if inside else block_at(cell_b)
			if b != null:
				data.bridges.append(_shape_bridge(rng, a, b, axis))
	return data
