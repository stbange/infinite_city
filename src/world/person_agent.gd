class_name PersonAgent
extends Node3D
## A simple figure for a person near the player (spec people-in-the-city): a body tinted by what
## they are doing and a head. The node origin is at the feet.

const COLORS := {
	"working": Color(0.25, 0.85, 0.8),
	"out": Color(1.0, 0.65, 0.25),
	"at home": Color(0.65, 0.45, 1.0),
	"walking": Color(0.9, 0.9, 0.95),
	"gang": Color(0.95, 0.15, 0.2),
}

static var _body_mesh: CapsuleMesh
static var _head_mesh: SphereMesh
static var _materials: Dictionary = {}

var person_key: String = ""
var label: String = ""
var activity: String = ""
var _body: MeshInstance3D
var _head: MeshInstance3D


func _init() -> void:
	if _body_mesh == null:
		_body_mesh = CapsuleMesh.new()
		_body_mesh.radius = 0.24
		_body_mesh.height = 1.45
		_head_mesh = SphereMesh.new()
		_head_mesh.radius = 0.13
		_head_mesh.height = 0.26
	_body = MeshInstance3D.new()
	_body.mesh = _body_mesh
	_body.position = Vector3(0, 0.725, 0)
	add_child(_body)
	_head = MeshInstance3D.new()
	_head.mesh = _head_mesh
	_head.position = Vector3(0, 1.6, 0)
	_head.material_override = _material(Color(0.85, 0.7, 0.6))
	add_child(_head)


func set_activity(kind: String) -> void:
	if kind == activity:
		return
	activity = kind
	_body.material_override = _material(COLORS.get(kind, COLORS["walking"]))


static func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.8
		m.emission_enabled = true
		m.emission = color * 0.15
		_materials[key] = m
	return _materials[key]
