class_name RouteHints
extends Node3D
## Small lights on the floor along the next stretch of the route to the next door (spec
## wayfinding / Route hints): only the next 30 m, so the fog keeps its secrets. H turns the hints
## on and off, J prefers routes that avoid bridges held by gangs. The scanner shows the whole way.

const AHEAD := 30.0
const SPACING := 2.5
const FULL_SECONDS := 10.0
const REFRESH_SECONDS := 1.0
const REPLAN_DISTANCE := 3.0
const GANG_PENALTY := 300.0
const BUDGET := 20000

@export var world_path: NodePath
@export var player_path: NodePath
@export var jobs_path: NodePath
@export var encounters_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var enabled: bool = true
var avoid_gangs: bool = false
var nav: CityNav
var route: NavRoute
var last_message: String = ""
var _lights: Array[MeshInstance3D] = []
var _since: float = 0.0
var _planned_from := Vector3.INF
var _planned_to := Vector3.INF
var _full_time: float = 0.0
var _light_mesh: SphereMesh
var _light_material: StandardMaterial3D


func _process(delta: float) -> void:
	_full_time = maxf(0.0, _full_time - delta)
	_since += delta
	if auto_update and _since >= REFRESH_SECONDS:
		_since = 0.0
		update()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_H:
			enabled = not enabled
			last_message = "Route hints on" if enabled else "Route hints off"
			update()
		KEY_J:
			avoid_gangs = not avoid_gangs
			last_message = "Avoiding gang bridges" if avoid_gangs else "Taking the shortest way"
			_planned_from = Vector3.INF
			update()


## Shows the whole route for a while (the scanner).
func show_full() -> void:
	_full_time = FULL_SECONDS
	update()


func lights_shown() -> int:
	var n := 0
	for light in _lights:
		n += 1 if light.visible else 0
	return n


func light_positions() -> PackedVector3Array:
	var result := PackedVector3Array()
	for light in _lights:
		if light.visible:
			result.append(light.global_position)
	return result


func update() -> void:
	var world := get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null
	var player := get_node_or_null(player_path) as Player if not player_path.is_empty() else null
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	if world == null or world.population == null or player == null or jobs == null or not enabled:
		_show(PackedVector3Array())
		return
	if nav == null or nav.population != world.population:
		nav = CityNav.new(world.population)
	var target := _target(jobs)
	if target.is_empty():
		_show(PackedVector3Array())
		return
	var feet := player.global_position
	var target_position: Vector3 = DoorPlaces.scene_position(world, target["cell"], target["floor"], target["unit"])
	if route == null or feet.distance_to(_planned_from) > REPLAN_DISTANCE or target_position != _planned_to:
		_plan(world, feet, target)
		_planned_from = feet
		_planned_to = target_position
	if route == null or route.is_empty():
		_show(PackedVector3Array())
		return
	var base := world.origin.scene_position_of_cell_center(route.start_cell)
	var reach := INF if _full_time > 0.0 else AHEAD
	var marks := PackedVector3Array()
	var d := SPACING
	while d <= minf(route.length, reach) and marks.size() < 200:
		var p := base + route.point_at(d)
		if p.distance_to(feet) <= reach + 2.0:
			marks.append(p + Vector3(0, 0.06, 0))
		d += SPACING
	_show(marks)


func _target(jobs: JobManager) -> Dictionary:
	if not jobs.carried.is_empty():
		var job := jobs.carried[0]
		return {"cell": job.dropoff_cell, "floor": job.dropoff_floor, "unit": job.dropoff_unit}
	if jobs.patron != null:
		return {"cell": jobs.patron.cell, "floor": jobs.patron.floor_index, "unit": jobs.patron.unit}
	return {}


func _plan(world: CityWorld, feet: Vector3, target: Dictionary) -> void:
	nav.bridge_penalties = _gang_penalties(world, feet) if avoid_gangs else {}
	var cell := world.origin.absolute_cell_of(feet)
	var local := feet - world.origin.scene_position_of_cell_center(cell)
	var start := nav.nearest_node(cell, local)
	var goal := nav.node_of(NavPlace.door(target["cell"], target["floor"], target["unit"]))
	route = nav.route_between(start, goal, CityNav.MAX_CELLS, BUDGET)


## Penalties for the bridges near the player that gangs hold.
func _gang_penalties(world: CityWorld, feet: Vector3) -> Dictionary:
	var encounters := get_node_or_null(encounters_path) as EncounterDirector if not encounters_path.is_empty() else null
	var turf := encounters.turf if encounters != null and encounters.turf != null else TurfMap.new(world.chronicle, world.layout)
	var penalties := {}
	var cell := world.origin.absolute_cell_of(feet)
	for dx in range(-3, 4):
		for dz in range(-3, 4):
			for dy in range(-1, 2):
				for bridge in world.layout.bridges_of(cell + Vector3i(dx, dy, dz)):
					if not turf.claim_of(bridge).is_empty():
						penalties[WorldOverlays.bridge_key(bridge)] = GANG_PENALTY
	return penalties


func _show(marks: PackedVector3Array) -> void:
	if _light_mesh == null:
		_light_mesh = SphereMesh.new()
		_light_mesh.radius = 0.09
		_light_mesh.height = 0.18
		_light_material = StandardMaterial3D.new()
		_light_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_light_material.albedo_color = Color(0.3, 1.0, 0.85)
	while _lights.size() < marks.size():
		var light := MeshInstance3D.new()
		light.mesh = _light_mesh
		light.material_override = _light_material
		add_child(light)
		_lights.append(light)
	for i in _lights.size():
		_lights[i].visible = i < marks.size()
		if i < marks.size():
			_lights[i].global_position = marks[i]
