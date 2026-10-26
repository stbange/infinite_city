class_name PocketLayout
extends RefCounted
## Decides which blocks carry a magic doorway, where it sits, and what lies behind it
## (specs pocket-doorways and pocket-spaces). Pure function of the seed and the cell.

const SALT_DOORWAY := 21
const SALT_POCKET := 22
const DOOR_SIZE := Vector2(4.0, 6.0)
## Clearance between the opening and the edges of its face, in metres.
const FACE_MARGIN := 1.0

var city: CityLayout
var doorway_chance: float = 0.10


func _init(city_layout: CityLayout) -> void:
	city = city_layout


static func kind_for(block_kind: int) -> int:
	match block_kind:
		BlockTypes.Kind.MARKET:
			return PocketSpaceInfo.Kind.BAZAAR
		BlockTypes.Kind.PARK, BlockTypes.Kind.FARM:
			return PocketSpaceInfo.Kind.GARDEN
		BlockTypes.Kind.TRANSIT_HUB:
			return PocketSpaceInfo.Kind.CONCOURSE
		_:
			return PocketSpaceInfo.Kind.HALL


## The doorway of the block in a cell, or null.
func doorway_of(cell: Vector3i) -> DoorwayInfo:
	var block := city.block_at(cell)
	return null if block == null else doorway_for_block(block)


## Doorways of already generated blocks (avoids regenerating them), in the given order.
func doorways_for_blocks(blocks: Array[BlockInfo]) -> Array[DoorwayInfo]:
	var result: Array[DoorwayInfo] = []
	for block in blocks:
		var doorway := doorway_for_block(block)
		if doorway != null:
			result.append(doorway)
	return result


## The doorway of a generated block, or null.
func doorway_for_block(block: BlockInfo) -> DoorwayInfo:
	var cell := block.cell
	var rng := CellRandom.new(DetHash.hash_cell(city.config.world_seed, SALT_DOORWAY, cell))
	var roll := rng.next_float()
	if block.kind != BlockTypes.Kind.TRANSIT_HUB and roll >= doorway_chance:
		return null
	# Prefer the end of a bridge with room above its deck.
	for bridge in city.bridges_of(cell):
		var deck_y := bridge.start.y
		if deck_y + DOOR_SIZE.y + FACE_MARGIN > block.max_local().y:
			continue
		var sign := 1 if bridge.cell_a == cell else -1
		var lateral_axis := _lateral(bridge.axis)
		return _make(block, bridge.axis, sign, bridge.start[lateral_axis], deck_y, true)
	# Otherwise a hashed face, position and height.
	var face := rng.next_int(4)
	var axis := Vector3.AXIS_X if face < 2 else Vector3.AXIS_Z
	var face_sign := 1 if face % 2 == 0 else -1
	var lat := _lateral(axis)
	var half_w := DOOR_SIZE.x * 0.5 + FACE_MARGIN
	var lateral := rng.range_float(block.min_local()[lat] + half_w, block.max_local()[lat] - half_w)
	var bottom := rng.range_float(block.min_local().y + FACE_MARGIN,
			block.max_local().y - DOOR_SIZE.y - FACE_MARGIN)
	return _make(block, axis, face_sign, lateral, bottom, false)


## Doorways of all blocks in a chunk, in z -> y -> x cell order.
func doorways_in_chunk(chunk: Vector3i) -> Array[DoorwayInfo]:
	var result: Array[DoorwayInfo] = []
	var origin := city.chunk_origin_cell(chunk)
	if origin.y - city.config.roof_layer > city.config.sky_layers:
		return result
	var n := city.config.chunk_cells
	for z in n:
		for y in n:
			for x in n:
				var doorway := doorway_of(origin + Vector3i(x, y, z))
				if doorway != null:
					result.append(doorway)
	return result


## The pocket space behind a doorway.
func pocket_of(doorway: DoorwayInfo) -> PocketSpaceInfo:
	var rng := CellRandom.new(DetHash.hash_cell(city.config.world_seed, SALT_POCKET, doorway.cell))
	var size := Vector3(roundf(rng.range_float(160.0, 320.0)), roundf(rng.range_float(60.0, 140.0)),
			roundf(rng.range_float(240.0, 480.0)))
	var inner_door := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -size.z * 0.5))
	return PocketSpaceInfo.new(doorway.cell, kind_for(doorway.block_kind), size, inner_door, rng.next_u32())


static func _lateral(axis: int) -> int:
	return Vector3.AXIS_Z if axis == Vector3.AXIS_X else Vector3.AXIS_X


func _make(block: BlockInfo, axis: int, face_sign: int, lateral: float, bottom: float, on_bridge: bool) -> DoorwayInfo:
	var out := Vector3()
	out[axis] = face_sign
	var basis := Basis(Vector3.UP.cross(out), Vector3.UP, out)
	var origin := Vector3()
	origin[axis] = block.max_local()[axis] if face_sign > 0 else block.min_local()[axis]
	origin[_lateral(axis)] = lateral
	origin.y = bottom
	return DoorwayInfo.new(block.cell, block.kind, axis, face_sign, Transform3D(basis, origin), on_bridge)
