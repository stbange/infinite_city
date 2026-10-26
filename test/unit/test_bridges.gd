extends GutTest
## Spec city-bridges.

const R := 0
const EPS := 0.01
const AXES: Array[int] = [Vector3.AXIS_X, Vector3.AXIS_Z]

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func _unit(axis: int) -> Vector3i:
	return Vector3i(1, 0, 0) if axis == Vector3.AXIS_X else Vector3i(0, 0, 1)


func _collect_bridges(count: int) -> Array[BridgeInfo]:
	var bridges: Array[BridgeInfo] = []
	var rng := CellRandom.new(6)
	while bridges.size() < count:
		var cell := Vector3i(rng.range_int(-300, 300), rng.range_int(R - 300, R), rng.range_int(-300, 300))
		for axis in AXES:
			var bridge := layout.bridge_between(cell, axis)
			if bridge != null:
				bridges.append(bridge)
	return bridges


func test_bridges_only_join_two_blocks() -> void:
	var rng := CellRandom.new(7)
	var found := 0
	for i in 5000:
		var cell := Vector3i(rng.range_int(-300, 300), rng.range_int(R - 300, R), rng.range_int(-300, 300))
		for axis in AXES:
			var bridge := layout.bridge_between(cell, axis)
			if bridge == null:
				continue
			found += 1
			assert_eq(bridge.cell_a, cell)
			assert_eq(bridge.cell_b, cell + _unit(axis))
			assert_true(bridge.axis == Vector3.AXIS_X or bridge.axis == Vector3.AXIS_Z)
			assert_true(layout.is_solid(bridge.cell_a) and layout.is_solid(bridge.cell_b))
	assert_gt(found, 0)


func test_share_of_bridged_pairs() -> void:
	var rng := CellRandom.new(8)
	var eligible := 0
	var bridged := 0
	while eligible < 4000:
		var cell := Vector3i(rng.range_int(-300, 300), rng.range_int(R - 300, R), rng.range_int(-300, 300))
		var axis := AXES[rng.next_int(2)]
		if not (layout.is_solid(cell) and layout.is_solid(cell + _unit(axis))):
			continue
		eligible += 1
		if layout.bridge_between(cell, axis) != null:
			bridged += 1
	assert_between(bridged / 4000.0, 0.22, 0.38)


func test_deck_spans_face_to_face() -> void:
	for bridge in _collect_bridges(500):
		var a := layout.block_at(bridge.cell_a)
		var b := layout.block_at(bridge.cell_b)
		var axis := bridge.axis
		var cell_len: float = layout.config.cell_size[axis]
		assert_almost_eq(bridge.start[axis], a.max_local()[axis], EPS)
		assert_almost_eq(bridge.end[axis], cell_len + b.min_local()[axis], EPS)
		# straight along the axis
		for other in 3:
			if other != axis:
				assert_almost_eq(bridge.start[other], bridge.end[other], EPS)


func test_deck_lies_within_both_blocks() -> void:
	for bridge in _collect_bridges(500):
		assert_almost_eq(bridge.width, 6.0, EPS)
		var a := layout.block_at(bridge.cell_a)
		var b := layout.block_at(bridge.cell_b)
		var lateral := Vector3.AXIS_Z if bridge.axis == Vector3.AXIS_X else Vector3.AXIS_X
		var left := bridge.start[lateral] - bridge.width * 0.5
		var right := bridge.start[lateral] + bridge.width * 0.5
		for block: BlockInfo in [a, b]:
			assert_true(left >= block.min_local()[lateral] - EPS and right <= block.max_local()[lateral] + EPS,
					"deck sticks out of %s sideways" % block.cell)
			assert_true(bridge.start.y >= block.min_local().y and bridge.start.y <= block.max_local().y,
					"deck height outside %s" % block.cell)


func test_listing_from_either_block() -> void:
	for bridge in _collect_bridges(100):
		var from_a := layout.bridges_of(bridge.cell_a)
		var from_b := layout.bridges_of(bridge.cell_b)
		assert_true(from_a.any(func(x: BridgeInfo) -> bool: return x.equals(bridge)), "missing from A")
		assert_true(from_b.any(func(x: BridgeInfo) -> bool: return x.equals(bridge)), "missing from B")


func test_open_air_cells_list_no_bridges() -> void:
	assert_eq(layout.bridges_of(Vector3i(0, 50, 0)).size(), 0)


func test_bridges_are_generated_once() -> void:
	var owners := {}  # key "cell_a/axis" -> Array of chunks
	for cx in range(-1, 2):
		for cy in range(-2, 0):
			for cz in range(-1, 2):
				var chunk := Vector3i(cx, cy, cz)
				for bridge in layout.generate_chunk(chunk).bridges:
					var key := "%s/%d" % [bridge.cell_a, bridge.axis]
					if not owners.has(key):
						owners[key] = []
					owners[key].append(chunk)
					assert_eq(layout.chunk_of(bridge.cell_a), chunk)
	# Ground truth: every bridge whose cells both lie in the group.
	var expected := 0
	for x in range(-4, 8):
		for y in range(-8, 0):
			for z in range(-4, 8):
				for axis in AXES:
					var cell := Vector3i(x, y, z)
					var neighbour := cell + _unit(axis)
					if neighbour.x >= 8 or neighbour.z >= 8:
						continue
					if layout.bridge_between(cell, axis) != null:
						expected += 1
						var key := "%s/%d" % [cell, axis]
						assert_true(owners.has(key), "bridge %s not generated" % key)
						if owners.has(key):
							assert_eq(owners[key].size(), 1, "bridge %s generated more than once" % key)
	assert_gt(expected, 0)


func test_deck_on_the_cell_centre_line_and_the_floor_grid() -> void:
	var cell_height := layout.config.cell_size.y
	for bridge in _collect_bridges(500):
		var lateral := Vector3.AXIS_Z if bridge.axis == Vector3.AXIS_X else Vector3.AXIS_X
		assert_almost_eq(bridge.start[lateral], 0.0, 0.001)
		var deck := (bridge.cell_a.y + 0.5) * cell_height + bridge.start.y
		assert_almost_eq(deck - roundf(deck / 4.0) * 4.0, 0.0, 0.001)
		for cell: Vector3i in [bridge.cell_a, bridge.cell_b]:
			var block := layout.block_at(cell)
			assert_gte(block.max_local().y - bridge.start.y, 4.0 - 0.001)
