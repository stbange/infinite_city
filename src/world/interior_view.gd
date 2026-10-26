class_name InteriorView
extends Node3D
## The interior of one entered block (spec block-interiors / Entering blocks). Node origin =
## the block's cell centre, so all InteriorFloor boxes are used as they are.
##
## build_step() builds one floor per call (data and visuals), starting at the player's floor.
## Once every floor exists the view is ready: it becomes visible and gets its solid shell (outer
## walls, bottom slab, roof); slabs, walls, stairs and furniture are solid only for the floors
## around the player (set_collision_floors()).

const _STRIDE := 12
const _STRIDE_EXTRA := 20
## Salt of the light anchor ids of room lights.
const _ANCHOR_SALT := 43
## Room lights: energy per unit of RoomInfo.light_energy and a soft falloff, so floors 3.3 m
## below the light are lit and not only the walls next to it.
const ROOM_LIGHT_ENERGY := 4.0
const ROOM_LIGHT_ATTENUATION := 1.0

static var _facade_material: ShaderMaterial
static var _glass_material: StandardMaterial3D
static var _slab_material: StandardMaterial3D
static var _wall_material: StandardMaterial3D
static var _stair_material: StandardMaterial3D
static var _item_material: StandardMaterial3D

var cell: Vector3i
var plan: InteriorPlan
var _layout: InteriorLayout
var _floors: Dictionary = {}       # int -> InteriorFloor
var _built: Dictionary = {}        # int -> true once drawn
var _floor_bodies: Dictionary = {} # int -> StaticBody3D
var _shell_body: StaticBody3D
var _ready_flag: bool = false
var _collision_centre: int = -1000


## Shared by every entered block; CityWorld keeps its roof height current.
static func facade_material() -> ShaderMaterial:
	if _facade_material == null:
		_facade_material = ShaderMaterial.new()
		_facade_material.shader = load("res://src/world/shaders/facade.gdshader")
	return _facade_material


static func _materials() -> void:
	if _glass_material != null:
		return
	_glass_material = StandardMaterial3D.new()
	_glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass_material.albedo_color = Color(0.05, 0.08, 0.12, 0.35)
	_glass_material.metallic = 0.6
	_glass_material.roughness = 0.08
	_glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_slab_material = StandardMaterial3D.new()
	_slab_material.albedo_color = Color(0.26, 0.24, 0.25)
	_slab_material.metallic = 0.1
	_slab_material.roughness = 0.4
	_wall_material = StandardMaterial3D.new()
	_wall_material.albedo_color = Color(0.27, 0.27, 0.29)
	_wall_material.roughness = 0.85
	_stair_material = StandardMaterial3D.new()
	_stair_material.albedo_color = Color(0.17, 0.17, 0.19)
	_stair_material.metallic = 0.5
	_stair_material.roughness = 0.45
	_item_material = StandardMaterial3D.new()
	_item_material.vertex_color_use_as_albedo = true
	_item_material.roughness = 0.65


func setup(p_plan: InteriorPlan, layout: InteriorLayout) -> void:
	plan = p_plan
	cell = p_plan.block.cell
	_layout = layout
	name = "Interior_%d_%d_%d" % [cell.x, cell.y, cell.z]
	top_level = true
	visible = false


## Floor data (generated on first use).
func floor(k: int) -> InteriorFloor:
	return floor_data(k)


func floor_data(k: int) -> InteriorFloor:
	if not _floors.has(k):
		_floors[k] = _layout.floor_of(plan, k)
	return _floors[k]


func is_ready() -> bool:
	return _ready_flag


func built_floor_count() -> int:
	return _built.size()


## Builds the next missing floor nearest to `focus_floor`. Returns true once the view is ready.
func build_step(focus_floor: int) -> bool:
	if _ready_flag:
		return true
	var next := _next_floor(clampi(focus_floor, 0, plan.floors - 1))
	if next >= 0:
		_build_floor(next)
	if _built.size() == plan.floors:
		_build_shell()
		visible = true
		_ready_flag = true
	return _ready_flag


func _next_floor(focus: int) -> int:
	for step in plan.floors * 2:
		var k := focus + (step + 1) / 2 * (1 if step % 2 == 1 else -1)
		if k >= 0 and k < plan.floors and not _built.has(k):
			return k
	return -1


## Local position (relative to the cell centre) of a scene position.
func local_of(scene_position: Vector3) -> Vector3:
	return scene_position - global_position


func contains(scene_position: Vector3) -> bool:
	return AABB(plan.block.min_local(), plan.block.size).has_point(local_of(scene_position))


## Distance from a scene position to the block's box (0 inside).
func distance_to(scene_position: Vector3) -> float:
	return InteriorView.box_distance(AABB(plan.block.min_local(), plan.block.size), local_of(scene_position))


static func box_distance(box: AABB, point: Vector3) -> float:
	var closest := point.clamp(box.position, box.end)
	return closest.distance_to(point)


## Floor index at a scene position (feet height; clamped to the block's floors).
func floor_index_at(scene_position: Vector3) -> int:
	return plan.floor_at(local_of(scene_position).y + 0.1)


func room_at(scene_position: Vector3) -> RoomInfo:
	var local := local_of(scene_position)
	return floor_data(floor_index_at(scene_position)).room_at(Vector2(local.x, local.z))


## Room lights of one floor, in scene coordinates. Only the player's floor is lit: slabs cast no
## shadows, and lights just below the feet would otherwise crowd out the rooms around the player.
func light_anchors(floor_index: int) -> Array[LightAnchor]:
	var result: Array[LightAnchor] = []
	if not _floors.has(floor_index):
		return result
	var f: InteriorFloor = _floors[floor_index]
	for i in f.rooms.size():
		var room := f.rooms[i]
		var reach := clampf(maxf(room.rect.size.x, room.rect.size.y) * 0.9, 5.0, 10.0)
		var id := DetHash.hash4(0, _ANCHOR_SALT, cell.x, cell.y, cell.z, floor_index * 1000 + i)
		result.append(LightAnchor.new(id, global_position + room.light, room.light_color,
				room.light_energy * ROOM_LIGHT_ENERGY, reach, ROOM_LIGHT_ATTENUATION))
	return result


## Makes the floors centre - 1 .. centre + 1 solid (their slabs, walls, stairs, furniture).
func set_collision_floors(center: int) -> void:
	if not _ready_flag or center == _collision_centre:
		return
	_collision_centre = center
	for k: int in _floor_bodies.keys():
		if absi(k - center) > 1:
			(_floor_bodies[k] as Node).queue_free()
			_floor_bodies.erase(k)
	for k in range(maxi(0, center - 1), mini(plan.floors, center + 2)):
		if not _floor_bodies.has(k):
			_floor_bodies[k] = _floor_body(k)


func collision_floors() -> Array[int]:
	var result: Array[int] = []
	for k: int in _floor_bodies:
		result.append(k)
	result.sort()
	return result


func _floor_body(k: int) -> StaticBody3D:
	var f := floor_data(k)
	var body := StaticBody3D.new()
	body.name = "Floor%d" % k
	add_child(body)
	for box in f.solids():
		_add_shape(body, box)
	for flight in f.flights:
		var xf := flight.ramp_transform()
		var shape := BoxShape3D.new()
		shape.size = xf.basis.get_scale()
		var node := CollisionShape3D.new()
		node.shape = shape
		node.transform = Transform3D(xf.basis.orthonormalized(), xf.origin)
		body.add_child(node)
	return body


func _build_shell() -> void:
	_shell_body = StaticBody3D.new()
	_shell_body.name = "Shell"
	add_child(_shell_body)
	for k in plan.floors:
		for box in floor_data(k).shell:
			_add_shape(_shell_body, box)
	for box in floor_data(0).slabs:
		_add_shape(_shell_body, box)
	var top := floor_data(plan.floors - 1)
	for box in top.roof:
		_add_shape(_shell_body, box)
	for box in top.hut:
		_add_shape(_shell_body, box)


static func _add_shape(body: StaticBody3D, box: AABB) -> void:
	if box.size.x <= 0.001 or box.size.y <= 0.001 or box.size.z <= 0.001:
		return
	var shape := BoxShape3D.new()
	shape.size = box.size
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = box.get_center()
	body.add_child(node)


func _build_floor(k: int) -> void:
	_materials()
	var f := floor_data(k)
	var holder := Node3D.new()
	holder.name = "Floor%dVisuals" % k
	add_child(holder)
	var facade: Array[AABB] = []
	facade.append_array(f.outer_walls)
	facade.append_array(f.roof)
	facade.append_array(f.hut)
	var accent := BlockTypes.color(plan.block.kind)
	var facade_colors := PackedColorArray()
	var facade_custom := PackedColorArray()
	for i in facade.size():
		facade_colors.append(accent)
		facade_custom.append(Color(plan.top(), 0.0, 0.0, 0.0))
	_add_boxes(holder, "Facade", facade, facade_material(), RenderLayers.CITY, facade_colors, facade_custom)
	_add_boxes(holder, "Glass", f.glass, _glass_material, RenderLayers.INTERIOR)
	_add_boxes(holder, "Slabs", f.slabs, _slab_material, RenderLayers.INTERIOR)
	_add_boxes(holder, "Walls", f.walls, _wall_material, RenderLayers.INTERIOR)
	var stairs: Array[AABB] = []
	stairs.append_array(f.stair_solids)
	stairs.append_array(f.steps)
	_add_boxes(holder, "Stairs", stairs, _stair_material, RenderLayers.INTERIOR)
	var matte: Array[AABB] = []
	var matte_colors := PackedColorArray()
	var glowing: Array[AABB] = []
	var glow_colors := PackedColorArray()
	var glow_custom := PackedColorArray()
	for i in f.items.size():
		if f.item_glow[i] > 0.0:
			glowing.append(f.items[i])
			glow_colors.append(f.item_colors[i])
			glow_custom.append(Color(0.0, 0.0, 1.0, f.item_glow[i]))
		else:
			matte.append(f.items[i])
			matte_colors.append(f.item_colors[i])
	for i in f.lamps.size():
		glowing.append(f.lamps[i])
		glow_colors.append(f.lamp_colors[i])
		glow_custom.append(Color(0.0, 0.0, 1.0, 2.5))
	_add_boxes(holder, "Furniture", matte, _item_material, RenderLayers.INTERIOR, matte_colors)
	_add_boxes(holder, "Lights", glowing, ChunkView.neon_material(), RenderLayers.INTERIOR, glow_colors, glow_custom)
	_built[k] = true


static func _add_boxes(parent: Node3D, node_name: String, boxes: Array[AABB], material: Material, layers: int,
		colors: PackedColorArray = PackedColorArray(), custom: PackedColorArray = PackedColorArray()) -> void:
	if boxes.is_empty():
		return
	var with_colors := not colors.is_empty()
	var with_custom := not custom.is_empty()
	var stride := _STRIDE + (4 if with_colors else 0) + (4 if with_custom else 0)
	var buffer := PackedFloat32Array()
	buffer.resize(boxes.size() * stride)
	for i in boxes.size():
		var box := boxes[i]
		var at := i * stride
		var centre := box.get_center()
		buffer[at] = box.size.x
		buffer[at + 3] = centre.x
		buffer[at + 5] = box.size.y
		buffer[at + 7] = centre.y
		buffer[at + 10] = box.size.z
		buffer[at + 11] = centre.z
		at += _STRIDE
		if with_colors:
			var c := colors[i]
			buffer[at] = c.r
			buffer[at + 1] = c.g
			buffer[at + 2] = c.b
			buffer[at + 3] = c.a
			at += 4
		if with_custom:
			var d := custom[i]
			buffer[at] = d.r
			buffer[at + 1] = d.g
			buffer[at + 2] = d.b
			buffer[at + 3] = d.a
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = with_colors
	multimesh.use_custom_data = with_custom
	multimesh.mesh = ChunkView.box_mesh()
	multimesh.instance_count = boxes.size()
	multimesh.buffer = buffer
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	instance.layers = layers
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
