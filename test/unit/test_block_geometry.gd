extends GutTest
## Spec city-layout: Block geometry, Floor grid.

const EPS := 1e-3

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func _collect_blocks(count: int) -> Array[BlockInfo]:
	var blocks: Array[BlockInfo] = []
	var rng := CellRandom.new(4)
	while blocks.size() < count:
		var cell := Vector3i(rng.range_int(-400, 400), rng.range_int(-400, 4), rng.range_int(-400, 400))
		var block := layout.block_at(cell)
		if block != null:
			blocks.append(block)
	return blocks


## True when a setback is allowed for a face whose boundary is (or is not) a lane.
func _setback_ok(axis: int, setback: float, lane: bool, bottom: bool) -> bool:
	var config := layout.config
	if lane:
		if axis == Vector3.AXIS_Y:
			return absf(setback - config.lane_setback) < EPS
		return setback >= config.lane_setback - EPS and setback <= config.lane_setback + config.lane_setback_jitter + EPS
	if axis == Vector3.AXIS_Y:
		var first := 0.0 if bottom else 4.0
		return absf(setback - first) < EPS or absf(setback - first - 4.0) < EPS
	return setback >= config.street_setback_min - EPS and setback <= config.street_setback_max + EPS


func test_blocks_stay_inside_their_cells() -> void:
	var half_cell := layout.config.cell_size * 0.5
	for block in _collect_blocks(2000):
		var lo := block.min_local()
		var hi := block.max_local()
		for axis in 3:
			assert_true(lo[axis] < 0.0 and hi[axis] > 0.0, "block %s misses its cell centre" % block.cell)
			var low_setback: float = lo[axis] + half_cell[axis]
			var high_setback: float = half_cell[axis] - hi[axis]
			var low_lane := layout.is_lane(axis, block.cell[axis])
			var high_lane := layout.is_lane(axis, block.cell[axis] + 1)
			assert_true(_setback_ok(axis, low_setback, low_lane, true),
					"block %s axis %d low setback %s (lane %s)" % [block.cell, axis, low_setback, low_lane])
			assert_true(_setback_ok(axis, high_setback, high_lane, false),
					"block %s axis %d high setback %s (lane %s)" % [block.cell, axis, high_setback, high_lane])


func test_narrow_streets() -> void:
	var rng := CellRandom.new(12)
	var pairs := 0
	var total := 0.0
	var tries := 0
	while pairs < 2000 and tries < 100000:
		tries += 1
		var cell := Vector3i(rng.range_int(-400, 400), rng.range_int(-200, 0), rng.range_int(-400, 400))
		var axis: int = Vector3.AXIS_X if rng.next_int(2) == 0 else Vector3.AXIS_Z
		var step := Vector3i.ZERO
		step[axis] = 1
		if layout.is_lane(axis, cell[axis] + 1):
			continue
		var a := layout.block_at(cell)
		var b := layout.block_at(cell + step)
		if a == null or b == null:
			continue
		var gap: float = (layout.config.cell_size[axis] * 0.5 - a.max_local()[axis]) \
				+ (layout.config.cell_size[axis] * 0.5 + b.min_local()[axis])
		assert_between(gap, 4.0 - EPS, 12.0 + EPS, "gap between %s and %s" % [a.cell, b.cell])
		total += gap
		pairs += 1
	assert_eq(pairs, 2000)
	assert_lt(total / pairs, 10.0)


func test_block_sizes_vary() -> void:
	var widths := {}
	for block in _collect_blocks(2000):
		widths[snappedf(block.size.x, 0.01)] = true
	assert_gte(widths.size(), 50)


func test_open_air_has_no_block() -> void:
	var cell := Vector3i(0, 100, 0)
	assert_null(layout.block_at(cell))
	assert_eq(layout.block_kind_at(cell), BlockTypes.NONE)


func test_block_data_is_deterministic() -> void:
	var other := CityLayout.new(CityConfig.new())
	for block in _collect_blocks(200):
		var again := other.block_at(block.cell)
		assert_not_null(again)
		assert_true(block.equals(again), "block %s differs between generators" % block.cell)


func test_block_world_aabb_near_origin() -> void:
	var block := _collect_blocks(1)[0]
	var aabb := layout.block_aabb(block)
	assert_almost_eq(aabb.get_center(), layout.cell_center(block.cell) + block.offset, Vector3.ONE * EPS)
	assert_almost_eq(aabb.size, block.size, Vector3.ONE * EPS)


func _on_grid(height: float) -> bool:
	return absf(height - roundf(height / 4.0) * 4.0) < 0.001


func test_blocks_on_the_floor_grid() -> void:
	var cell_height := layout.config.cell_size.y
	for block in _collect_blocks(2000):
		var centre_y := (block.cell.y + 0.5) * cell_height
		assert_true(_on_grid(centre_y + block.min_local().y), "bottom of %s off the grid" % block.cell)
		assert_true(_on_grid(centre_y + block.max_local().y), "top of %s off the grid" % block.cell)
		assert_between(block.size.y, 32.0 - EPS, 60.0 + EPS)
