extends GutTest
## Specs pocket-doorways and pocket-spaces (pure logic).

const EPS := 0.01
const DOOR_W := 4.0
const DOOR_H := 6.0

var city: CityLayout
var pockets: PocketLayout


func before_each() -> void:
	city = CityLayout.new(CityConfig.new())
	pockets = PocketLayout.new(city)


func _sample_blocks(count: int, salt: int) -> Array[BlockInfo]:
	var blocks: Array[BlockInfo] = []
	var rng := CellRandom.new(salt)
	while blocks.size() < count:
		var block := city.block_at(Vector3i(rng.range_int(-300, 300), rng.range_int(-300, 4), rng.range_int(-300, 300)))
		if block != null:
			blocks.append(block)
	return blocks


func _sample_doorways(count: int) -> Array[DoorwayInfo]:
	var doorways: Array[DoorwayInfo] = []
	var rng := CellRandom.new(77)
	while doorways.size() < count:
		var doorway := pockets.doorway_of(Vector3i(rng.range_int(-300, 300), rng.range_int(-300, 4), rng.range_int(-300, 300)))
		if doorway != null:
			doorways.append(doorway)
	return doorways


func test_doorway_frequency() -> void:
	var checked := 0
	var with_door := 0
	for block in _sample_blocks(4400, 11):
		if block.kind == BlockTypes.Kind.TRANSIT_HUB:
			continue
		checked += 1
		if pockets.doorway_of(block.cell) != null:
			with_door += 1
		if checked == 4000:
			break
	assert_between(float(with_door) / checked, 0.07, 0.13)


func test_transit_hubs_always_have_a_doorway() -> void:
	var hubs := 0
	for dx in 5:
		for dz in 4:
			var plan := city.district_plan(Vector3i(dx, -2, dz))
			for cell: Vector3i in plan:
				if plan[cell] == BlockTypes.Kind.TRANSIT_HUB:
					hubs += 1
					assert_not_null(pockets.doorway_of(cell), "hub %s has no doorway" % cell)
	assert_eq(hubs, 20)


func test_open_air_has_no_doorway() -> void:
	assert_null(pockets.doorway_of(Vector3i(0, 100, 0)))


func test_same_doorways_every_time() -> void:
	var other := PocketLayout.new(CityLayout.new(CityConfig.new()))
	for block in _sample_blocks(500, 12):
		var a := pockets.doorway_of(block.cell)
		var b := other.doorway_of(block.cell)
		assert_eq(a == null, b == null)
		if a != null:
			assert_true(a.equals(b), "doorway of %s differs" % block.cell)


func test_doorways_sit_on_a_side_face() -> void:
	for doorway in _sample_doorways(500):
		var block := city.block_at(doorway.cell)
		var axis := doorway.face_axis
		var lateral := Vector3.AXIS_Z if axis == Vector3.AXIS_X else Vector3.AXIS_X
		var face := block.max_local()[axis] if doorway.face_sign > 0 else block.min_local()[axis]
		var normal := Vector3()
		normal[axis] = doorway.face_sign
		assert_almost_eq(doorway.door.origin[axis], face, EPS)
		assert_almost_eq(doorway.door.basis.z, normal, Vector3.ONE * EPS)
		assert_almost_eq(doorway.door.basis.y, Vector3.UP, Vector3.ONE * EPS)
		for corner: Vector3 in [Vector3(-DOOR_W / 2, 0, 0), Vector3(DOOR_W / 2, 0, 0),
				Vector3(-DOOR_W / 2, DOOR_H, 0), Vector3(DOOR_W / 2, DOOR_H, 0)]:
			var p := doorway.door * corner
			assert_true(p[lateral] >= block.min_local()[lateral] + 1.0 - EPS and p[lateral] <= block.max_local()[lateral] - 1.0 + EPS,
					"doorway of %s leaves its face sideways" % doorway.cell)
			assert_true(p.y >= block.min_local().y + 1.0 - EPS and p.y <= block.max_local().y - 1.0 + EPS,
					"doorway of %s leaves its face vertically" % doorway.cell)


func test_doorway_at_the_end_of_a_bridge() -> void:
	var checked := 0
	for doorway in _sample_doorways(600):
		var block := city.block_at(doorway.cell)
		var chosen: BridgeInfo = null
		for bridge in city.bridges_of(doorway.cell):
			if bridge.start.y + DOOR_H + 1.0 <= block.max_local().y:
				chosen = bridge
				break
		if chosen == null:
			assert_false(doorway.on_bridge)
			continue
		checked += 1
		var lateral := Vector3.AXIS_Z if chosen.axis == Vector3.AXIS_X else Vector3.AXIS_X
		var sign := 1 if chosen.cell_a == doorway.cell else -1
		assert_true(doorway.on_bridge)
		assert_eq(doorway.face_axis, chosen.axis)
		assert_eq(doorway.face_sign, sign)
		assert_almost_eq(doorway.door.origin.y, chosen.start.y, EPS)
		assert_almost_eq(doorway.door.origin[lateral], chosen.start[lateral], EPS)
	assert_gt(checked, 20)


func test_chunk_doorways_equal_per_block_queries() -> void:
	var chunk := Vector3i(1, -1, 2)
	var from_chunk := pockets.doorways_in_chunk(chunk)
	var expected: Array[DoorwayInfo] = []
	var origin := city.chunk_origin_cell(chunk)
	for z in 4:
		for y in 4:
			for x in 4:
				var doorway := pockets.doorway_of(origin + Vector3i(x, y, z))
				if doorway != null:
					expected.append(doorway)
	assert_eq(from_chunk.size(), expected.size())
	for i in expected.size():
		assert_true(from_chunk[i].equals(expected[i]))


func test_interior_dwarfs_the_block() -> void:
	for doorway in _sample_doorways(300):
		var block := city.block_at(doorway.cell)
		var pocket := pockets.pocket_of(doorway)
		var block_volume := block.size.x * block.size.y * block.size.z
		assert_gte(pocket.volume(), 10.0 * block_volume)
		var widest := maxf(block.size.x, block.size.z)
		assert_gte(pocket.size.x, 2.0 * widest)
		assert_gte(pocket.size.z, 2.0 * widest)


func test_kinds_by_function() -> void:
	assert_eq(PocketLayout.kind_for(BlockTypes.Kind.MARKET), PocketSpaceInfo.Kind.BAZAAR)
	assert_eq(PocketLayout.kind_for(BlockTypes.Kind.PARK), PocketSpaceInfo.Kind.GARDEN)
	assert_eq(PocketLayout.kind_for(BlockTypes.Kind.FARM), PocketSpaceInfo.Kind.GARDEN)
	assert_eq(PocketLayout.kind_for(BlockTypes.Kind.TRANSIT_HUB), PocketSpaceInfo.Kind.CONCOURSE)
	assert_eq(PocketLayout.kind_for(BlockTypes.Kind.HOUSING), PocketSpaceInfo.Kind.HALL)
	for doorway in _sample_doorways(50):
		assert_eq(pockets.pocket_of(doorway).kind, PocketLayout.kind_for(doorway.block_kind))


func test_same_interior_every_time() -> void:
	var other := PocketLayout.new(CityLayout.new(CityConfig.new()))
	for doorway in _sample_doorways(20):
		var a := pockets.pocket_of(doorway)
		var b := other.pocket_of(other.doorway_of(doorway.cell))
		assert_eq(a.kind, b.kind)
		assert_eq(a.size, b.size)
		assert_eq(a.inner_door, b.inner_door)
		var ca := a.contents()
		var cb := b.contents()
		assert_eq(ca.pillars, cb.pillars)
		assert_eq(ca.props, cb.props)
		assert_eq(ca.prop_colors, cb.prop_colors)
		assert_eq(ca.lights, cb.lights)
		assert_eq(ca.monument, cb.monument)


func test_inner_door_on_the_entrance_wall() -> void:
	for doorway in _sample_doorways(50):
		var pocket := pockets.pocket_of(doorway)
		assert_almost_eq(pocket.inner_door.origin, Vector3(0, 0, -pocket.size.z / 2), Vector3.ONE * EPS)
		assert_almost_eq(pocket.inner_door.basis.z, Vector3(0, 0, 1), Vector3.ONE * EPS)
		assert_almost_eq(pocket.inner_door.basis.y, Vector3.UP, Vector3.ONE * EPS)


func test_contents_stay_inside_the_room_and_clear_the_doorway() -> void:
	for doorway in _sample_doorways(30):
		var pocket := pockets.pocket_of(doorway)
		var room := AABB(Vector3(-pocket.size.x / 2, 0, -pocket.size.z / 2), pocket.size).grow(0.01)
		var contents := pocket.contents()
		var door_lane := AABB(Vector3(-6, 0, -pocket.size.z / 2), Vector3(12, 10, 30))
		var all: Array[AABB] = []
		all.append_array(contents.pillars)
		all.append_array(contents.props)
		all.append_array(contents.lights)
		all.append(contents.monument)
		assert_eq(contents.prop_colors.size(), contents.props.size())
		assert_gt(contents.pillars.size() + contents.props.size(), 10)
		for box in all:
			assert_true(room.encloses(box), "content %s outside the room" % box)
			assert_false(door_lane.intersects(box), "content %s blocks the doorway" % box)
