class_name TrafficManager
extends Node3D
## Draws the flying cars near the player and reports when one hits them (spec flying-traffic).

signal hit()

const VIEW_RADIUS := 220.0
const BODY_COLOR := Color(0.12, 0.12, 0.16)
const HEAD_COLOR := Color(1.0, 0.95, 0.8)
const TAIL_COLOR := Color(1.0, 0.1, 0.2)

@export var world_path: NodePath
@export var session_path: NodePath
@export var player_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var lanes: TrafficLanes
var _bodies: Array[Node3D] = []
var _visible_count: int = 0
var _was_hit: bool = false

static var _body_mesh: BoxMesh
static var _light_mesh: BoxMesh
static var _materials: Dictionary = {}


func _process(_delta: float) -> void:
	if auto_update:
		update()


func car_count() -> int:
	return _visible_count


## Real seconds of the clock's time (game minutes at its speed).
static func seconds_of(clock: GameClock) -> float:
	return clock.exact_minutes() / maxf(clock.speed, 0.0001)


func update() -> void:
	var world := _world()
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	var player := get_node_or_null(player_path) as Player if not player_path.is_empty() else null
	if world == null or world.layout == null or session == null or player == null:
		return
	if lanes == null:
		lanes = TrafficLanes.new(world.layout)
	var cell := world.origin.absolute_cell_of(player.global_position)
	var base := world.origin.scene_position_of_cell_center(cell)
	var cars := lanes.cars_near(cell, VIEW_RADIUS, seconds_of(session.clock))
	while _bodies.size() < cars.size():
		_bodies.append(_make_body())
	for i in _bodies.size():
		var body := _bodies[i]
		body.visible = i < cars.size()
		if not body.visible:
			continue
		var car: Dictionary = cars[i]
		body.global_position = base + (car["position"] as Vector3)
		var velocity: Vector3 = car["velocity"]
		body.global_basis = Basis.looking_at(velocity.normalized(), Vector3.UP)
	_visible_count = cars.size()
	var feet := player.global_position - base
	var touching := TrafficLanes.hits(cars, feet + Vector3(0, 0.9, 0))
	if touching and not _was_hit:
		hit.emit()
	_was_hit = touching


func _make_body() -> Node3D:
	if _body_mesh == null:
		_body_mesh = BoxMesh.new()
		_body_mesh.size = Vector3(TrafficLanes.CAR_SIZE.x, TrafficLanes.CAR_SIZE.y, TrafficLanes.CAR_SIZE.z)
		_light_mesh = BoxMesh.new()
		_light_mesh.size = Vector3(0.5, 0.18, 0.08)
	var root := Node3D.new()
	add_child(root)
	var body := MeshInstance3D.new()
	body.mesh = _body_mesh
	body.material_override = _material(BODY_COLOR, false)
	root.add_child(body)
	# Looking along -z: head lights at the front (-z), tail lights at the back (+z).
	for side: float in [-0.7, 0.7]:
		var head := MeshInstance3D.new()
		head.mesh = _light_mesh
		head.material_override = _material(HEAD_COLOR, true)
		head.position = Vector3(side, 0.1, -TrafficLanes.CAR_SIZE.z * 0.5 - 0.02)
		root.add_child(head)
		var tail := MeshInstance3D.new()
		tail.mesh = _light_mesh
		tail.material_override = _material(TAIL_COLOR, true)
		tail.position = Vector3(side, 0.1, TrafficLanes.CAR_SIZE.z * 0.5 + 0.02)
		root.add_child(tail)
	return root


static func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var key := color.to_html() + str(glowing)
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		if glowing:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = 4.0
		else:
			m.metallic = 0.6
			m.roughness = 0.3
		_materials[key] = m
	return _materials[key]


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null
