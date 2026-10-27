class_name CityFog
extends Node
## Heavy, drifting city fog (spec city-fog). A full-screen quad with `city_fog.gdshader` hangs in
## front of the player's camera on the FOG visual layer; every camera that draws that layer gets
## the fog (the main camera outside pocket spaces, the portal camera when it shows the city).
## refresh() keeps the shader in step with the player's depth, the floating origin, the entered
## blocks (no fog inside them) and pocket spaces (no fog inside them).

## The fog banks repeat every NOISE_PERIOD metres, so their offset stays small at any depth.
const NOISE_PERIOD := 1024
## How far the fog is marched along each ray (beyond it everything is fog anyway).
const MAX_DISTANCE := 900.0
## Fog banks: noise scale, how much they change the density, and the wind that moves them (m/s).
const BANK_SIZE := 64.0
const BANK_STRENGTH := 0.9
const WIND := Vector3(2.2, 0.35, 1.3)

@export var world_path: NodePath
## The Player (its camera carries the quad).
@export var camera_path: NodePath
@export var pocket_manager_path: NodePath
@export var interiors_path: NodePath

static var _material: ShaderMaterial

var _quad: MeshInstance3D


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://src/world/shaders/city_fog.gdshader")
		_material.render_priority = Material.RENDER_PRIORITY_MAX
		_material.set_shader_parameter("noise_period", float(NOISE_PERIOD))
		_material.set_shader_parameter("max_distance", MAX_DISTANCE)
		_material.set_shader_parameter("bank_size", BANK_SIZE)
		_material.set_shader_parameter("bank_strength", BANK_STRENGTH)
		_material.set_shader_parameter("wind", WIND)
	return _material


func _process(_delta: float) -> void:
	refresh()


## The fog quad (null until the camera exists).
func quad() -> MeshInstance3D:
	return _quad


func refresh() -> void:
	var world := get_node_or_null(world_path) as CityWorld
	var player := get_node_or_null(camera_path) as Player
	if world == null or player == null or world.origin == null or player.camera == null:
		return
	_ensure_quad(player.camera)
	var fog := material()
	var depth := world.focus_depth_layers()
	var cell_height := world.config.cell_size.y
	fog.set_shader_parameter("density_below", Atmosphere.below_density(depth))
	fog.set_shader_parameter("density_above", Atmosphere.ABOVE_DENSITY)
	fog.set_shader_parameter("clear_layers", Atmosphere.CLEAR_LAYERS)
	fog.set_shader_parameter("sea_depth", Atmosphere.FOG_SEA_DEPTH)
	fog.set_shader_parameter("sea_band", Atmosphere.FOG_SEA_BAND)
	fog.set_shader_parameter("color_below", Atmosphere.below_color(depth))
	fog.set_shader_parameter("color_above", Atmosphere.ABOVE_FOG)
	fog.set_shader_parameter("sun_haze", Atmosphere.SUN_HAZE)
	fog.set_shader_parameter("sun_fade", Atmosphere.SUN_FADE_M)
	fog.set_shader_parameter("layer_height", cell_height)
	var roof_bottom := world.origin.scene_position_of_cell(Vector3i(0, world.config.roof_layer, 0)).y
	fog.set_shader_parameter("roof_bottom_y", roof_bottom)
	fog.set_shader_parameter("roof_top_y", roof_bottom + cell_height)
	fog.set_shader_parameter("noise_offset", noise_offset(world.origin))
	_update_clear_boxes(fog)
	var pockets := get_node_or_null(pocket_manager_path) as PocketManager \
			if not pocket_manager_path.is_empty() else null
	var in_pocket := pockets != null and pockets.is_inside()
	player.camera.set_cull_mask_value(RenderLayers.FOG_LAYER_NUMBER, not in_pocket)


## Absolute position of the scene origin modulo the noise period, so fog banks keep their place
## in the world when the floating origin moves.
static func noise_offset(origin: FloatingOrigin) -> Vector3:
	var size := origin.chunk_size()
	var result := Vector3()
	for axis in 3:
		result[axis] = float(posmod(origin.origin_chunk[axis] * int(size[axis]), NOISE_PERIOD))
	return result


## Scene boxes without fog: the ready interiors (their block plus the slab under floor 0).
func clear_boxes() -> Array[AABB]:
	var boxes: Array[AABB] = []
	var interiors := get_node_or_null(interiors_path) as InteriorManager \
			if not interiors_path.is_empty() else null
	if interiors == null:
		return boxes
	for view in interiors.views():
		if view.is_ready():
			var block := view.plan.block
			var lo := view.global_position + block.min_local() - Vector3(0, InteriorLayout.SLAB, 0)
			boxes.append(AABB(lo, block.size + Vector3(0, InteriorLayout.SLAB, 0)))
	return boxes


func _update_clear_boxes(fog: ShaderMaterial) -> void:
	var boxes := clear_boxes()
	for i in 2:
		var lo := Vector3.ONE
		var hi := -Vector3.ONE
		if i < boxes.size():
			lo = boxes[i].position
			hi = boxes[i].end
		fog.set_shader_parameter("clear_min_%d" % i, lo)
		fog.set_shader_parameter("clear_max_%d" % i, hi)


func _ensure_quad(camera: Camera3D) -> void:
	if _quad != null and is_instance_valid(_quad):
		return
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2, 2)
	_quad = MeshInstance3D.new()
	_quad.name = "FogQuad"
	_quad.mesh = mesh
	_quad.material_override = material()
	_quad.layers = RenderLayers.FOG
	_quad.extra_cull_margin = 16384.0
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_quad.position = Vector3(0, 0, -1)
	camera.add_child(_quad)
