class_name PersonAgent
extends Node3D
## A simple figure for a person near the player (spec people-in-the-city): a torso tinted by what
## they are doing, a head and two legs that swing while walking (spec doorsteps / Figures). The node
## origin is at the feet.

const COLORS := {
	"working": Color(0.25, 0.85, 0.8),
	"out": Color(1.0, 0.65, 0.25),
	"at home": Color(0.65, 0.45, 1.0),
	"walking": Color(0.9, 0.9, 0.95),
	"gang": Color(0.95, 0.15, 0.2),
	"warden": Color(0.3, 0.45, 1.0),
}

const STRIDE_RATE := 7.0
const STRIDE_ANGLE := 0.5

static var _body_mesh: CapsuleMesh
static var _head_mesh: SphereMesh
static var _leg_mesh: CapsuleMesh
static var _materials: Dictionary = {}

var person_key: String = ""
var label: String = ""
var activity: String = ""
var _body: MeshInstance3D
var _head: MeshInstance3D
var _legs: Array[Node3D] = []
var _phase: float = 0.0
var _last_position := Vector3.INF
## Seconds of walking animation shown (tests read it).
var walk_phase: float:
	get:
		return _phase


func _init() -> void:
	if _body_mesh == null:
		_body_mesh = CapsuleMesh.new()
		_body_mesh.radius = 0.24
		_body_mesh.height = 0.8
		_leg_mesh = CapsuleMesh.new()
		_leg_mesh.radius = 0.09
		_leg_mesh.height = 0.85
		_head_mesh = SphereMesh.new()
		_head_mesh.radius = 0.13
		_head_mesh.height = 0.26
	_body = MeshInstance3D.new()
	_body.mesh = _body_mesh
	_body.position = Vector3(0, 1.15, 0)
	add_child(_body)
	for side: float in [-0.12, 0.12]:
		var hip := Node3D.new()
		hip.position = Vector3(side, 0.85, 0)
		var leg := MeshInstance3D.new()
		leg.mesh = _leg_mesh
		leg.position = Vector3(0, -0.42, 0)
		leg.material_override = _material(Color(0.12, 0.1, 0.16))
		hip.add_child(leg)
		add_child(hip)
		_legs.append(hip)
	_head = MeshInstance3D.new()
	_head.mesh = _head_mesh
	_head.position = Vector3(0, 1.6, 0)
	_head.material_override = _material(Color(0.85, 0.7, 0.6))
	add_child(_head)


## Swings the legs when the figure moved since the last frame, eases them back when it stands.
func animate(delta: float) -> void:
	var moved := _last_position != Vector3.INF and global_position.distance_to(_last_position) > 0.01
	_last_position = global_position
	if moved:
		_phase += delta * STRIDE_RATE
	else:
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, minf(1.0, delta * 8.0))
	var swing := sin(_phase) * STRIDE_ANGLE
	_legs[0].rotation.x = swing
	_legs[1].rotation.x = -swing


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
