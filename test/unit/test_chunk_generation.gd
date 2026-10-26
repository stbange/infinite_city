extends GutTest
## Spec city-layout: Chunk generation, Deterministic generation.

const R := 0


func _layout(seed_value: int = 1337) -> CityLayout:
	var config := CityConfig.new()
	config.world_seed = seed_value
	return CityLayout.new(config)


func _chunks_equal(a: ChunkData, b: ChunkData) -> bool:
	if a.blocks.size() != b.blocks.size() or a.bridges.size() != b.bridges.size():
		return false
	for i in a.blocks.size():
		if not a.blocks[i].equals(b.blocks[i]):
			return false
	for i in a.bridges.size():
		if not a.bridges[i].equals(b.bridges[i]):
			return false
	return true


func test_chunk_content_equals_per_cell_queries() -> void:
	var layout := _layout()
	var chunk := Vector3i(-2, -1, 3)
	var data := layout.generate_chunk(chunk)
	assert_eq(data.chunk, chunk)
	var by_cell := {}
	for block in data.blocks:
		by_cell[block.cell] = block
	var origin := layout.chunk_origin_cell(chunk)
	var solid := 0
	for x in 4:
		for y in 4:
			for z in 4:
				var cell := origin + Vector3i(x, y, z)
				var expected := layout.block_at(cell)
				if expected == null:
					assert_false(by_cell.has(cell), "chunk has a block in open-air cell %s" % cell)
				else:
					solid += 1
					assert_true(by_cell.has(cell) and expected.equals(by_cell[cell]), "chunk block %s differs" % cell)
	assert_eq(data.blocks.size(), solid)
	assert_gt(solid, 0)


func test_chunks_above_the_city_are_empty() -> void:
	var layout := _layout()
	for chunk: Vector3i in [Vector3i(0, 2, 0), Vector3i(-7, 3, 11), Vector3i(1000, 500, -1000)]:
		var data := layout.generate_chunk(chunk)
		assert_true(data.is_empty(), "chunk %s should be empty" % chunk)


func test_generation_order_does_not_matter() -> void:
	var a := _layout()
	var b := _layout()
	var first := Vector3i(0, -1, 0)
	var second := Vector3i(5, -3, 2)
	var a1 := a.generate_chunk(first)
	var a2 := a.generate_chunk(second)
	var b2 := b.generate_chunk(second)
	var b1 := b.generate_chunk(first)
	assert_true(_chunks_equal(a1, b1))
	assert_true(_chunks_equal(a2, b2))


func test_repeated_queries_agree() -> void:
	var cell := Vector3i(12, -40, -7)
	var a := _layout().block_at(cell)
	var b := _layout().block_at(cell)
	assert_eq(a == null, b == null)
	if a != null:
		assert_true(a.equals(b))


func test_the_seed_changes_the_city() -> void:
	var one := _layout(1)
	var two := _layout(2)
	var rng := CellRandom.new(10)
	var differ := 0
	for i in 1000:
		var cell := Vector3i(rng.range_int(-200, 200), rng.range_int(R - 200, R), rng.range_int(-200, 200))
		if one.is_solid(cell) != two.is_solid(cell):
			differ += 1
	assert_gte(differ, 200)


func test_chunk_generation_time() -> void:
	var layout := _layout()
	var start := Time.get_ticks_usec()
	var count := 0
	for x in range(-3, 3):
		for y in range(-2, 0):
			for z in range(-2, 1):
				layout.generate_chunk(Vector3i(x, y, z))
				count += 1
	var avg_ms := (Time.get_ticks_usec() - start) / 1000.0 / count
	gut.p("average chunk generation: %.2f ms over %d chunks" % [avg_ms, count])
	assert_lt(avg_ms, 50.0)
