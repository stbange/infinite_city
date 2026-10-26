extends GutTest
## Spec city-rendering: Blocks are drawn where they are generated, Bridges are drawn as decks.

const EPS := 0.001

var layout: CityLayout
var origin: FloatingOrigin


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())
	origin = FloatingOrigin.for_config(layout.config)


## A chunk below the roof that has blocks and owns bridges.
func _interesting_chunk() -> ChunkData:
	for x in range(0, 20):
		var data := layout.generate_chunk(Vector3i(x, -2, 1))
		if data.blocks.size() > 5 and data.bridges.size() > 1:
			return data
	return null


func _make_view(data: ChunkData) -> ChunkView:
	var view := ChunkView.new()
	add_child_autofree(view)
	view.build(data, layout, origin)
	return view


func test_one_box_per_block() -> void:
	origin.origin_chunk = Vector3i(3, -1, 0)
	var data := _interesting_chunk()
	var view := _make_view(data)
	assert_eq(view.block_count(), data.blocks.size())
	assert_eq(view.position, origin.scene_position_of_chunk(data.chunk))
	for i in data.blocks.size():
		var block := data.blocks[i]
		var xf := view.block_transform(i)
		var expected_centre := origin.scene_position_of_cell_center(block.cell) + block.offset
		assert_almost_eq(view.position + xf.origin, expected_centre, Vector3.ONE * EPS)
		assert_almost_eq(xf.basis.get_scale(), block.size, Vector3.ONE * EPS)


func test_function_colours() -> void:
	var data := _interesting_chunk()
	var view := _make_view(data)
	for i in data.blocks.size():
		assert_eq(view.block_color(i), BlockTypes.color(data.blocks[i].kind))


func test_hospital_and_farm_colours_differ() -> void:
	assert_ne(BlockTypes.color(BlockTypes.Kind.HOSPITAL), BlockTypes.color(BlockTypes.Kind.FARM))


func test_one_deck_per_bridge() -> void:
	var data := _interesting_chunk()
	var view := _make_view(data)
	assert_eq(view.bridge_count(), data.bridges.size())
	for i in data.bridges.size():
		var bridge := data.bridges[i]
		var scale := view.bridge_transform(i).basis.get_scale()
		var lateral := Vector3.AXIS_Z if bridge.axis == Vector3.AXIS_X else Vector3.AXIS_X
		assert_almost_eq(scale[bridge.axis], bridge.length(), EPS)
		assert_almost_eq(scale[lateral], bridge.width, EPS)


func test_deck_sits_between_its_blocks() -> void:
	var data := _interesting_chunk()
	var view := _make_view(data)
	for i in data.bridges.size():
		var bridge := data.bridges[i]
		var centre := view.position + view.bridge_transform(i).origin
		var expected := origin.scene_position_of_cell_center(bridge.cell_a) + (bridge.start + bridge.end) * 0.5
		assert_almost_eq(centre.x, expected.x, EPS)
		assert_almost_eq(centre.z, expected.z, EPS)
		# deck top surface at walking height
		var top := centre.y + view.bridge_transform(i).basis.get_scale().y * 0.5
		assert_almost_eq(top, expected.y, EPS)


func test_multimeshes_are_sized() -> void:
	var data := _interesting_chunk()
	var view := _make_view(data)
	assert_eq(view.blocks_instance().multimesh.instance_count, data.blocks.size())
	assert_eq(view.bridges_instance().multimesh.instance_count, data.bridges.size())


func test_empty_chunk_view() -> void:
	var view := _make_view(ChunkData.new(Vector3i(0, 5, 0)))
	assert_eq(view.block_count(), 0)
	assert_eq(view.bridge_count(), 0)


func _lit_chunk() -> Array:
	var lighting := CityLighting.new(layout)
	var pockets := PocketLayout.new(layout)
	for x in range(0, 20):
		var data := layout.generate_chunk(Vector3i(x, -2, 2))
		var signs: Array[SignInfo] = []
		for block in data.blocks:
			signs.append_array(lighting.signs_of(block, pockets.doorway_for_block(block)))
		var lamps: Array[LampInfo] = []
		for bridge in data.bridges:
			lamps.append_array(lighting.lamps_of(bridge))
		if signs.size() >= 3 and lamps.size() >= 4:
			return [data, signs, lamps]
	return []


func test_signs_and_lamps_are_drawn() -> void:
	var lit := _lit_chunk()
	assert_false(lit.is_empty())
	var data: ChunkData = lit[0]
	var signs: Array[SignInfo] = lit[1]
	var lamps: Array[LampInfo] = lit[2]
	var view := ChunkView.new()
	add_child_autofree(view)
	view.build(data, layout, origin, [], signs, lamps)
	assert_eq(view.sign_count(), signs.size())
	assert_eq(view.lamp_count(), lamps.size())
	for i in signs.size():
		var sign := signs[i]
		var xf := view.sign_transform(i)
		assert_almost_eq(view.position + xf.origin, origin.scene_position_of_cell_center(sign.cell) + sign.centre, Vector3.ONE * EPS)
		var scale := xf.basis.get_scale()
		var lat := CityLighting.lateral_axis(sign.face_axis)
		assert_almost_eq(scale[lat], sign.size.x, EPS)
		assert_almost_eq(scale.y, sign.size.y, EPS)


func test_signs_and_lamps_offer_light_anchors() -> void:
	var lit := _lit_chunk()
	var data: ChunkData = lit[0]
	var signs: Array[SignInfo] = lit[1]
	var lamps: Array[LampInfo] = lit[2]
	var view := ChunkView.new()
	add_child_autofree(view)
	view.build(data, layout, origin, [], signs, lamps)
	var anchors := view.light_anchors()
	assert_eq(anchors.size(), signs.size() + lamps.size())
	var ids := {}
	for anchor in anchors:
		ids[anchor.id] = true
	assert_eq(ids.size(), anchors.size(), "anchor ids must be unique")
	var lamp_anchor := anchors[signs.size()]
	var expected := origin.scene_position_of_cell_center(lamps[0].cell_a) + lamps[0].position
	assert_almost_eq(lamp_anchor.position, expected, Vector3.ONE * 0.5)
	assert_eq(lamp_anchor.color, lamps[0].color)


func test_two_railings_per_deck() -> void:
	var data := _interesting_chunk()
	var view := _make_view(data)
	assert_eq(view.railing_count(), data.bridges.size() * 2)
	for i in data.bridges.size():
		var bridge := data.bridges[i]
		for side in 2:
			var scale := view.railing_transform(i * 2 + side).basis.get_scale()
			assert_almost_eq(scale[bridge.axis], bridge.length(), EPS)
			assert_almost_eq(scale.y, 1.1, EPS)


func test_magic_doorways_leave_a_gap_in_the_block() -> void:
	var pockets := PocketLayout.new(layout)
	var checked := 0
	var rng := CellRandom.new(31)
	while checked < 30:
		var doorway := pockets.doorway_of(Vector3i(rng.range_int(-200, 200), rng.range_int(-100, 0), rng.range_int(-200, 200)))
		if doorway == null:
			continue
		checked += 1
		var block := layout.block_at(doorway.cell)
		var boxes := ChunkView.block_collision_boxes(block, doorway)
		# A point 0.6 m behind the face, in the middle of the opening, must be free.
		var probe := doorway.door * Vector3(0, 3, -0.6)
		var beside := doorway.door * Vector3(0, 3, -1.5)
		var probe_hit := false
		var beside_hit := false
		for box in boxes:
			probe_hit = probe_hit or box.has_point(probe)
			beside_hit = beside_hit or box.has_point(beside)
		assert_false(probe_hit, "the doorway gap of %s is blocked" % doorway.cell)
		assert_true(beside_hit, "behind the gap the block of %s must be solid" % doorway.cell)
