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


func doorway_views() -> Array[DoorwayView]:
	return _doorway_views


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
