class_name ChunkView
extends Node3D
## Renders one chunk: its blocks and bridge decks as two MultiMeshes (spec city-rendering).
## Instance data is packed into buffers and uploaded in one call; the buffers are kept so the
## drawn instances can be inspected (block_transform(), block_color(), ...).

## Floats per block instance: 12 transform + 4 colour + 4 custom data.
const BLOCK_STRIDE := 20
## Floats per bridge instance: 12 transform.
const BRIDGE_STRIDE := 12
## Floats per sign instance: 12 transform + 4 colour + 4 custom data.
const SIGN_STRIDE := 20
const DECK_THICKNESS := 1.2
const SIGN_THICKNESS := 0.3
const POST_SIZE := Vector3(0.14, 3.2, 0.14)
const HEAD_SIZE := Vector3(0.6, 0.18, 0.6)
const RAILING_HEIGHT := 1.1
const RAILING_THICKNESS := 0.08
## Depth of the walkable gap a magic doorway leaves in its block's collision shape.
const DOORWAY_GAP := 1.0
const _WINDOW_SALT := 99

static var _box_mesh: BoxMesh
static var _block_material: ShaderMaterial
static var _bridge_material: ShaderMaterial
static var _neon_material: ShaderMaterial
static var _post_material: StandardMaterial3D

var chunk: Vector3i
var _block_buffer := PackedFloat32Array()
var _bridge_buffer := PackedFloat32Array()
var _blocks_mmi: MultiMeshInstance3D
var _bridges_mmi: MultiMeshInstance3D
var _doorway_views: Array[DoorwayView] = []
var _sign_buffer := PackedFloat32Array()
var _lamp_count: int = 0
## Light anchors with positions relative to this node.
var _local_anchors: Array[LightAnchor] = []
var _railing_buffer := PackedFloat32Array()
var _data: ChunkData
var _doorways: Array[DoorwayInfo] = []
var _cell_size := Vector3.ONE
var _origin_cell := Vector3i.ZERO
var _body: StaticBody3D


static func box_mesh() -> BoxMesh:
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
		_box_mesh.size = Vector3.ONE
	return _box_mesh


## Shared by every chunk so the whole city batches into few draw calls.
static func block_material() -> ShaderMaterial:
	if _block_material == null:
		_block_material = ShaderMaterial.new()
		_block_material.shader = load("res://src/world/shaders/block.gdshader")
	return _block_material


static func bridge_material() -> ShaderMaterial:
	if _bridge_material == null:
		_bridge_material = ShaderMaterial.new()
		_bridge_material.shader = load("res://src/world/shaders/bridge.gdshader")
	return _bridge_material


static func neon_material() -> ShaderMaterial:
	if _neon_material == null:
		_neon_material = ShaderMaterial.new()
		_neon_material.shader = load("res://src/world/shaders/neon.gdshader")
	return _neon_material


static func post_material() -> StandardMaterial3D:
	if _post_material == null:
		_post_material = StandardMaterial3D.new()
		_post_material.albedo_color = Color(0.1, 0.1, 0.12)
		_post_material.metallic = 0.7
		_post_material.roughness = 0.35
	return _post_material


func build(data: ChunkData, layout: CityLayout, origin: FloatingOrigin,
		doorways: Array[DoorwayInfo] = [], signs: Array[SignInfo] = [], lamps: Array[LampInfo] = []) -> void:
	chunk = data.chunk
	name = "Chunk_%d_%d_%d" % [chunk.x, chunk.y, chunk.z]
	position = origin.scene_position_of_chunk(chunk)
	var cell_size := layout.config.cell_size
	var origin_cell := layout.chunk_origin_cell(chunk)
	_data = data
	_doorways = doorways
	_cell_size = cell_size
	_origin_cell = origin_cell
	var half := Vector3(0.5, 0.5, 0.5)

	_block_buffer.resize(data.blocks.size() * BLOCK_STRIDE)
	for i in data.blocks.size():
		var block := data.blocks[i]
		var centre := (Vector3(block.cell - origin_cell) + half) * cell_size + block.offset
		var at := i * BLOCK_STRIDE
		_write_transform(_block_buffer, at, Transform3D(Basis.from_scale(block.size), centre))
		_write_color(_block_buffer, at + 12, BlockTypes.color(block.kind))
		var window_seed := DetHash.u01(DetHash.hash_cell(layout.config.world_seed, _WINDOW_SALT, block.cell))
		_write_color(_block_buffer, at + 16, Color(window_seed, block.kind / 16.0, 0.0, 0.0))

	_bridge_buffer.resize(data.bridges.size() * BRIDGE_STRIDE)
	for i in data.bridges.size():
		var bridge := data.bridges[i]
		var lateral := Vector3.AXIS_Z if bridge.axis == Vector3.AXIS_X else Vector3.AXIS_X
		var scale := Vector3()
		scale[bridge.axis] = bridge.length()
		scale[lateral] = bridge.width
		scale.y = DECK_THICKNESS
		var centre := (Vector3(bridge.cell_a - origin_cell) + half) * cell_size \
				+ (bridge.start + bridge.end) * 0.5 - Vector3(0, DECK_THICKNESS * 0.5, 0)
		_write_transform(_bridge_buffer, i * BRIDGE_STRIDE, Transform3D(Basis.from_scale(scale), centre))

	_blocks_mmi = _make_instance("Blocks", block_material(), _block_buffer, data.blocks.size(), true)
	_bridges_mmi = _make_instance("Bridges", bridge_material(), _bridge_buffer, data.bridges.size(), false)

	for doorway in doorways:
		var view := DoorwayView.new()
		add_child(view)
		view.build(doorway)
		view.transform = Transform3D(doorway.door.basis,
				(Vector3(doorway.cell - origin_cell) + half) * cell_size + doorway.door.origin)
		_doorway_views.append(view)

	_build_signs(signs, layout, origin_cell)
	_build_lamps(lamps, layout, origin_cell)
	_build_railings()


func doorway_views() -> Array[DoorwayView]:
	return _doorway_views


func railing_count() -> int:
	return _railing_buffer.size() / BRIDGE_STRIDE


func railing_transform(index: int) -> Transform3D:
	return _read_transform(_railing_buffer, index * BRIDGE_STRIDE)


func has_collision() -> bool:
	return _body != null


## Number of collision boxes while collision is enabled.
func collision_box_count() -> int:
	return 0 if _body == null else _body.get_child_count()


## Builds or drops the solid shapes of this chunk (spec on-foot-movement / Solid city near the player).
func set_collision_enabled(enabled: bool) -> void:
	if enabled == (_body != null):
		return
	if not enabled:
		_body.queue_free()
		_body = null
		return
	_body = StaticBody3D.new()
	_body.name = "Solid"
	add_child(_body)
	var doorway_by_cell := {}
	for doorway in _doorways:
		doorway_by_cell[doorway.cell] = doorway
	for block in _data.blocks:
		var centre := _cell_centre(block.cell)
		var doorway: DoorwayInfo = doorway_by_cell.get(block.cell)
		for box in block_collision_boxes(block, doorway):
			_add_box(AABB(box.position + centre, box.size))
	for i in _data.bridges.size():
		_add_box_transform(bridge_transform(i))
	for i in railing_count():
		_add_box_transform(railing_transform(i))


## Solid boxes of a block relative to its cell centre: the block's box, or — with a magic
## doorway — the box with a DOORWAY_GAP deep opening in front of the doorway.
static func block_collision_boxes(block: BlockInfo, doorway: DoorwayInfo) -> Array[AABB]:
	var lo := block.min_local()
	var hi := block.max_local()
	var boxes: Array[AABB] = []
	if doorway == null:
		boxes.append(AABB(lo, hi - lo))
		return boxes
	var axis := doorway.face_axis
	var lat := CityLighting.lateral_axis(axis)
	var core_lo := lo
	var core_hi := hi
	var slab_lo := lo
	var slab_hi := hi
	if doorway.face_sign > 0:
		core_hi[axis] -= DOORWAY_GAP
		slab_lo[axis] = core_hi[axis]
	else:
		core_lo[axis] += DOORWAY_GAP
		slab_hi[axis] = core_lo[axis]
	boxes.append(AABB(core_lo, core_hi - core_lo))
	var door_lat := doorway.door.origin[lat]
	var half := PocketLayout.DOOR_SIZE.x * 0.5
	var door_bottom := doorway.door.origin.y
	var door_top := door_bottom + PocketLayout.DOOR_SIZE.y
	# Four slab pieces around the opening: left, right (full height), below and above.
	var pieces: Array[Array] = [
		[slab_lo[lat], door_lat - half, slab_lo.y, slab_hi.y],
		[door_lat + half, slab_hi[lat], slab_lo.y, slab_hi.y],
		[door_lat - half, door_lat + half, slab_lo.y, door_bottom],
		[door_lat - half, door_lat + half, door_top, slab_hi.y],
	]
	for piece in pieces:
		if piece[1] - piece[0] <= 0.001 or piece[3] - piece[2] <= 0.001:
			continue
		var p_lo := slab_lo
		var p_hi := slab_hi
		p_lo[lat] = piece[0]
		p_hi[lat] = piece[1]
		p_lo.y = piece[2]
		p_hi.y = piece[3]
		boxes.append(AABB(p_lo, p_hi - p_lo))
	return boxes


func _cell_centre(cell: Vector3i) -> Vector3:
	return (Vector3(cell - _origin_cell) + Vector3(0.5, 0.5, 0.5)) * _cell_size


func _add_box(box: AABB) -> void:
	var shape := BoxShape3D.new()
	shape.size = box.size
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = box.get_center()
	_body.add_child(node)


func _add_box_transform(xf: Transform3D) -> void:
	_add_box(AABB(xf.origin - xf.basis.get_scale() * 0.5, xf.basis.get_scale()))


func _build_railings() -> void:
	_railing_buffer.resize(_data.bridges.size() * 2 * BRIDGE_STRIDE)
	var half := Vector3(0.5, 0.5, 0.5)
	for i in _data.bridges.size():
		var bridge := _data.bridges[i]
		var lat := CityLighting.lateral_axis(bridge.axis)
		var scale := Vector3()
		scale[bridge.axis] = bridge.length()
		scale[lat] = RAILING_THICKNESS
		scale.y = RAILING_HEIGHT
		for side in 2:
			var centre := (Vector3(bridge.cell_a - _origin_cell) + half) * _cell_size + (bridge.start + bridge.end) * 0.5
			centre[lat] += (1.0 if side == 1 else -1.0) * (bridge.width * 0.5 - RAILING_THICKNESS * 0.5)
			centre.y += RAILING_HEIGHT * 0.5
			_write_transform(_railing_buffer, (i * 2 + side) * BRIDGE_STRIDE, Transform3D(Basis.from_scale(scale), centre))
	if _data.bridges.size() > 0:
		_make_instance("Railings", post_material(), _railing_buffer, _data.bridges.size() * 2, false)


func sign_count() -> int:
	return _sign_buffer.size() / SIGN_STRIDE


func sign_transform(index: int) -> Transform3D:
	return _read_transform(_sign_buffer, index * SIGN_STRIDE)


func lamp_count() -> int:
	return _lamp_count


## Light anchors of this chunk's signs and lamps, in scene coordinates.
func light_anchors() -> Array[LightAnchor]:
	var result: Array[LightAnchor] = []
	for anchor in _local_anchors:
		result.append(LightAnchor.new(anchor.id, position + anchor.position, anchor.color, anchor.energy,
				anchor.light_range))
	return result


func _build_signs(signs: Array[SignInfo], layout: CityLayout, origin_cell: Vector3i) -> void:
	_sign_buffer.resize(signs.size() * SIGN_STRIDE)
	var cell_size := layout.config.cell_size
	var half := Vector3(0.5, 0.5, 0.5)
	for i in signs.size():
		var sign := signs[i]
		var lat := CityLighting.lateral_axis(sign.face_axis)
		var scale := Vector3()
		scale[lat] = sign.size.x
		scale.y = sign.size.y
		scale[sign.face_axis] = SIGN_THICKNESS
		var centre := (Vector3(sign.cell - origin_cell) + half) * cell_size + sign.centre
		var at := i * SIGN_STRIDE
		_write_transform(_sign_buffer, at, Transform3D(Basis.from_scale(scale), centre))
		_write_color(_sign_buffer, at + 12, sign.color)
		_write_color(_sign_buffer, at + 16, Color(sign.pattern_seed, 1.0 if sign.flicker else 0.0, 0.0, 0.0))
		var normal := Vector3()
		normal[sign.face_axis] = sign.face_sign
		var id := DetHash.hash4(0, 41, sign.cell.x, sign.cell.y, sign.cell.z, i)
		_local_anchors.append(LightAnchor.new(id, centre + normal * 1.5, sign.color, 2.5, 16.0))
	if signs.size() > 0:
		_make_instance("Signs", neon_material(), _sign_buffer, signs.size(), true)


func _build_lamps(lamps: Array[LampInfo], layout: CityLayout, origin_cell: Vector3i) -> void:
	_lamp_count = lamps.size()
	if lamps.is_empty():
		return
	var cell_size := layout.config.cell_size
	var half := Vector3(0.5, 0.5, 0.5)
	var posts := PackedFloat32Array()
	posts.resize(lamps.size() * BRIDGE_STRIDE)
	var heads := PackedFloat32Array()
	heads.resize(lamps.size() * SIGN_STRIDE)
	for i in lamps.size():
		var lamp := lamps[i]
		var head := (Vector3(lamp.cell_a - origin_cell) + half) * cell_size + lamp.position
		_write_transform(posts, i * BRIDGE_STRIDE,
				Transform3D(Basis.from_scale(POST_SIZE), head - Vector3(0, POST_SIZE.y * 0.5, 0)))
		_write_transform(heads, i * SIGN_STRIDE, Transform3D(Basis.from_scale(HEAD_SIZE), head))
		_write_color(heads, i * SIGN_STRIDE + 12, lamp.color)
		_write_color(heads, i * SIGN_STRIDE + 16, Color(0.0, 0.0, 1.0, 0.0))
		var id := DetHash.hash4(0, 42, lamp.cell_a.x, lamp.cell_a.y, lamp.cell_a.z, i)
		_local_anchors.append(LightAnchor.new(id, head - Vector3(0, 0.4, 0), lamp.color, 1.8, 14.0))
	_make_instance("LampPosts", post_material(), posts, lamps.size(), false)
	_make_instance("LampHeads", neon_material(), heads, lamps.size(), true)


func block_count() -> int:
	return _block_buffer.size() / BLOCK_STRIDE


func bridge_count() -> int:
	return _bridge_buffer.size() / BRIDGE_STRIDE


func block_transform(index: int) -> Transform3D:
	return _read_transform(_block_buffer, index * BLOCK_STRIDE)


func block_color(index: int) -> Color:
	var at := index * BLOCK_STRIDE + 12
	return Color(_block_buffer[at], _block_buffer[at + 1], _block_buffer[at + 2], _block_buffer[at + 3])


func bridge_transform(index: int) -> Transform3D:
	return _read_transform(_bridge_buffer, index * BRIDGE_STRIDE)


func blocks_instance() -> MultiMeshInstance3D:
	return _blocks_mmi


func bridges_instance() -> MultiMeshInstance3D:
	return _bridges_mmi


func _make_instance(node_name: String, material: Material, buffer: PackedFloat32Array, count: int,
		with_extras: bool) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = with_extras
	multimesh.use_custom_data = with_extras
	multimesh.mesh = box_mesh()
	multimesh.instance_count = count
	if count > 0:
		multimesh.buffer = buffer
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


## MultiMesh buffer layout: the 3x4 matrix row by row (basis rows, then origin component).
static func _write_transform(buffer: PackedFloat32Array, at: int, xf: Transform3D) -> void:
	var b := xf.basis
	buffer[at] = b.x.x
	buffer[at + 1] = b.y.x
	buffer[at + 2] = b.z.x
	buffer[at + 3] = xf.origin.x
	buffer[at + 4] = b.x.y
	buffer[at + 5] = b.y.y
	buffer[at + 6] = b.z.y
	buffer[at + 7] = xf.origin.y
	buffer[at + 8] = b.x.z
	buffer[at + 9] = b.y.z
	buffer[at + 10] = b.z.z
	buffer[at + 11] = xf.origin.z


static func _read_transform(buffer: PackedFloat32Array, at: int) -> Transform3D:
	var basis := Basis(Vector3(buffer[at], buffer[at + 4], buffer[at + 8]),
			Vector3(buffer[at + 1], buffer[at + 5], buffer[at + 9]),
			Vector3(buffer[at + 2], buffer[at + 6], buffer[at + 10]))
	return Transform3D(basis, Vector3(buffer[at + 3], buffer[at + 7], buffer[at + 11]))


static func _write_color(buffer: PackedFloat32Array, at: int, color: Color) -> void:
	buffer[at] = color.r
	buffer[at + 1] = color.g
	buffer[at + 2] = color.b
	buffer[at + 3] = color.a
