class_name DoorwayView
extends Node3D
## A magic doorway: a glowing frame and a surface that shimmers when idle and shows the portal
## camera's image when live. The node transform is the door transform (see PortalMath).

const FRAME_THICKNESS := 0.5
const FRAME_DEPTH := 0.8

static var _frame_material: StandardMaterial3D
static var _portal_shader: Shader

var doorway: DoorwayInfo
var _surface_material: ShaderMaterial


static func frame_material() -> StandardMaterial3D:
	if _frame_material == null:
		_frame_material = StandardMaterial3D.new()
		_frame_material.albedo_color = Color(0.12, 0.06, 0.18)
		_frame_material.emission_enabled = true
		_frame_material.emission = Color(0.62, 0.22, 1.0)
		_frame_material.emission_energy_multiplier = 1.1
	return _frame_material


func build(info: DoorwayInfo) -> void:
	doorway = info
	name = "Doorway_%d_%d_%d" % [info.cell.x, info.cell.y, info.cell.z]
	var size := PortalMath.DOOR_SIZE
	if _portal_shader == null:
		_portal_shader = load("res://src/world/shaders/portal.gdshader")
	_surface_material = ShaderMaterial.new()
	_surface_material.shader = _portal_shader
	var quad := QuadMesh.new()
	quad.size = size
	var surface := MeshInstance3D.new()
	surface.name = "Surface"
	surface.mesh = quad
	surface.position = Vector3(0, size.y * 0.5, 0.05)
	surface.material_override = _surface_material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)
	var t := FRAME_THICKNESS
	var z := FRAME_DEPTH * 0.5
	_add_bar("Left", Vector3(-(size.x + t) * 0.5, (size.y + t) * 0.5, z), Vector3(t, size.y + t, FRAME_DEPTH))
	_add_bar("Right", Vector3((size.x + t) * 0.5, (size.y + t) * 0.5, z), Vector3(t, size.y + t, FRAME_DEPTH))
	_add_bar("Top", Vector3(0, size.y + t * 0.5, z), Vector3(size.x + 2.0 * t, t, FRAME_DEPTH))


## Shows `texture` (the portal camera's image) on the surface; null goes back to the shimmer.
func set_portal_texture(texture: Texture2D) -> void:
	_surface_material.set_shader_parameter("portal_texture", texture)
	_surface_material.set_shader_parameter("live", 1.0 if texture != null else 0.0)


func is_live() -> bool:
	return float(_surface_material.get_shader_parameter("live")) > 0.5


func _add_bar(bar_name: String, centre: Vector3, size: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	var bar := MeshInstance3D.new()
	bar.name = bar_name
	bar.mesh = box
	bar.position = centre
	bar.material_override = frame_material()
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bar)
