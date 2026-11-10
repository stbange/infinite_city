class_name TraversalTools
extends Node3D
## The courier's tools (spec traversal-tools): grapple (G), glider (hold Space while falling),
## scanner (R) and flares (X), usable once bought in the shop.

const GRAPPLE_RANGE := 20.0
const SCAN_RANGE := 200.0
const SCAN_SECONDS := 10.0

@export var player_path: NodePath
@export var jobs_path: NodePath
@export var encounters_path: NodePath

var last_message: String = ""
var _beacon: MeshInstance3D
var _beacon_time: float = 0.0


func _process(delta: float) -> void:
	var player := _player()
	var jobs := _jobs()
	if player != null and jobs != null:
		player.glider_enabled = jobs.has_tool("glider")
	if _beacon_time > 0.0:
		_beacon_time -= delta
		if _beacon_time <= 0.0 and _beacon != null:
			_beacon.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var player := _player()
	if player == null or not player.input_enabled or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_G:
			grapple()
		KEY_R:
			scan()
		KEY_X:
			flare()


## Pulls the player onto the surface they aim at within reach; true when it worked.
func grapple() -> bool:
	var player := _player()
	var jobs := _jobs()
	if player == null or jobs == null or not jobs.has_tool("grapple") or player.camera == null:
		return false
	var eye := player.eye_position()
	var forward := -player.camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(eye, eye + forward * GRAPPLE_RANGE)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		last_message = "Nothing to grapple within %d m" % roundi(GRAPPLE_RANGE)
		return false
	player.global_position = (hit["position"] as Vector3) + (hit["normal"] as Vector3) * 0.4 + Vector3.UP
	player.velocity = Vector3.ZERO
	last_message = ""
	return true


## Shows a beacon at the next door when it is within range; true when shown.
func scan() -> bool:
	var player := _player()
	var jobs := _jobs()
	if player == null or jobs == null or not jobs.has_tool("scanner"):
		return false
	var waypoint := jobs.waypoint()
	if waypoint.is_empty():
		return false
	var target: Vector3 = waypoint["position"]
	if target.distance_to(player.global_position) > SCAN_RANGE:
		last_message = "Scanner: out of range"
		return false
	if _beacon == null:
		_beacon = MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.25
		mesh.bottom_radius = 0.25
		mesh.height = 60.0
		_beacon.mesh = mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.3, 1.0, 0.8, 0.7)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.no_depth_test = true
		_beacon.material_override = material
		add_child(_beacon)
	_beacon.global_position = target
	_beacon.visible = true
	_beacon_time = SCAN_SECONDS
	return true


func beacon_visible() -> bool:
	return _beacon != null and _beacon.visible


func beacon_position() -> Vector3:
	return _beacon.global_position if _beacon != null else Vector3.ZERO


## Ends a chase with a flare; true when one was used.
func flare() -> bool:
	var jobs := _jobs()
	var encounters := get_node_or_null(encounters_path) as EncounterDirector if not encounters_path.is_empty() else null
	if jobs == null or encounters == null or not jobs.has_tool("flare"):
		return false
	if not encounters.break_chase("Your flare blinds them — you slip away"):
		return false
	jobs.tools["flare"] = int(jobs.tools["flare"]) - 1
	if int(jobs.tools["flare"]) <= 0:
		jobs.tools.erase("flare")
	return true


func _player() -> Player:
	return get_node_or_null(player_path) as Player if not player_path.is_empty() else null


func _jobs() -> JobManager:
	return get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
