extends GutTest
## Spec faction-traces: Gang tags at turf edges, Memorials, Ruins.

var layout: CityLayout
var chronicle: CityChronicle
var traces: TraceLayout

const REACHES: Array[Vector3i] = [Vector3i(0, -1, 0), Vector3i(2, -3, -1), Vector3i(-3, -2, 4),
		Vector3i(5, -6, 2), Vector3i(-1, -9, -7), Vector3i(4, -4, -4)]


func before_all() -> void:
	var config := CityConfig.new()
	layout = CityLayout.new(config)
	chronicle = CityChronicle.new(config)
	traces = TraceLayout.new(chronicle, layout)


func _blocks_of(reach: Vector3i, stride: int) -> Array[BlockInfo]:
	var result: Array[BlockInfo] = []
	for district in chronicle.reach(reach).districts():
		var origin := layout.district_origin_cell(district)
		for x in range(0, 8, stride):
			for y in range(0, 8, stride):
				for z in range(0, 8, stride):
					var block := layout.block_at(origin + Vector3i(x, y, z))
					if block != null:
						result.append(block)
	return result


func _edge_owner(block: BlockInfo) -> FactionInfo:
	var district := layout.district_of(block.cell)
	var owner := chronicle.faction(chronicle.owner_of_district(district))
	if owner == null or owner.type != "gang":
		return null
	var local := layout.local_in_district(block.cell)
	for axis in 3:
		for direction: int in [-1, 1]:
			var on_edge := local[axis] == (0 if direction < 0 else layout.config.district_size - 1)
			if not on_edge:
				continue
			var step := Vector3i.ZERO
			step[axis] = direction
			if chronicle.owner_of_district(district + step) != owner.key:
				return owner
	return null


func test_tags_mark_turf_edges() -> void:
	var tagged := 0
	for reach in REACHES:
		for block in _blocks_of(reach, 1):
			var tags := traces.tags_of(block, null, [])
			var owner := _edge_owner(block)
			if owner == null:
				assert_eq(tags.size(), 0, "block %s is not on a turf edge" % block.cell)
				continue
			assert_between(tags.size(), 1, 3, "edge block %s" % block.cell)
			for tag in tags:
				assert_eq(tag.color, owner.color)
				assert_lte(tag.size.x, 2.5 + 1e-4)
				assert_lte(tag.size.y, 1.5 + 1e-4)
			tagged += 1
	assert_gt(tagged, 0)


func test_memorials_where_blood_was_spilled() -> void:
	for reach in REACHES:
		var rh := chronicle.reach(reach)
		for district in rh.districts():
			var memorial_cell := traces.memorial_cell(district)
			var block := layout.block_at(memorial_cell)
			if block == null:
				continue
			var memorials := traces.memorials_of(block, null, [])
			assert_eq(memorials.size(), 1 if traces.is_damaged(district) else 0, "district %s" % district)
		for block in _blocks_of(reach, 3):
			if block.cell != traces.memorial_cell(layout.district_of(block.cell)):
				assert_eq(traces.memorials_of(block, null, []).size(), 0)


func test_share_of_ruins() -> void:
	var damaged_blocks := 0
	var ruined := 0
	var undamaged_blocks := 0
	var reach_index := 0
	var rng := CellRandom.new(3)
	while (damaged_blocks < 3000 or undamaged_blocks < 1000) and reach_index < 400:
		var reach := Vector3i(rng.range_int(-30, 30), -rng.range_int(1, 20), rng.range_int(-30, 30))
		reach_index += 1
		for district in chronicle.reach(reach).districts():
			var damaged := traces.is_damaged(district)
			if (damaged and damaged_blocks >= 3000) or (not damaged and undamaged_blocks >= 1000):
				continue
			var origin := layout.district_origin_cell(district)
			for i in 64:
				var cell := origin + Vector3i(i % 8, (i / 8) % 8, (i * 3) % 8)
				if not layout.is_solid(cell):
					continue
				if damaged:
					damaged_blocks += 1
					if traces.is_ruined(cell):
						ruined += 1
				else:
					undamaged_blocks += 1
					assert_false(traces.is_ruined(cell))
	assert_gte(damaged_blocks, 3000)
	assert_between(float(ruined) / damaged_blocks, 0.18, 0.32)


## GUT keeps finished test scripts alive; release the big generators.
func after_all() -> void:
	layout = null
	chronicle = null
	traces = null
