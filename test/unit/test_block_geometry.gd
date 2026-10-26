extends GutTest
## Spec city-layout: Block geometry.

const CLEARANCE := 4.0
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


func test_blocks_stay_inside_their_cells() -> void:
	var half_cell := layout.config.cell_size * 0.5
	for block in _collect_blocks(2000):
		var lo := block.min_local()
		var hi := block.max_local()
		for axis in 3:
			assert_true(lo[axis] >= -half_cell[axis] + CLEARANCE - EPS, "block %s pokes out (min)" % block.cell)
			assert_true(hi[axis] <= half_cell[axis] - CLEARANCE + EPS, "block %s pokes out (max)" % block.cell)
			assert_true(lo[axis] < 0.0 and hi[axis] > 0.0, "block %s misses its cell centre" % block.cell)


func test_block_sizes_vary() -> void:
	var widths := {}
	var cell_width := layout.config.cell_size.x
	for block in _collect_blocks(2000):
		assert_between(block.size.x, cell_width * 0.55 - EPS, cell_width * 0.85 + EPS)
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
		assert_between(block.size.y, 36.0 - EPS, 52.0 + EPS)
