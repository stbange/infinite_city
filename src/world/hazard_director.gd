class_name HazardDirector
extends Node
## The rescue drone (spec hazards / Rescue drone): after a fall or a car hit the courier is put back
## on safe ground, pays the fee and loses the cargo.

static var FEE: int:
	get:
		return Economy.whole("hazards", "rescue_fee")
const MESSAGE_SECONDS := 8.0

@export var player_path: NodePath
@export var jobs_path: NodePath
@export var traffic_path: NodePath

## Emitted after each rescue.
signal rescued()

var last_message: String = ""
var rescues: int = 0
var _message_time: float = 0.0
var _connected: bool = false


func _process(delta: float) -> void:
	_connect()
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			last_message = ""


func _connect() -> void:
	if _connected:
		return
	var player := _player()
	if player == null:
		return
	player.rescued.connect(_on_rescued)
	var traffic := get_node_or_null(traffic_path) as TrafficManager if not traffic_path.is_empty() else null
	if traffic != null:
		traffic.hit.connect(_on_hit)
	_connected = true


func _on_hit() -> void:
	var player := _player()
	if player != null and player.fall_guard.has_safe_point():
		player.global_position = player.fall_guard.reset_point()
		player.velocity = Vector3.ZERO
	rescue("car")


func _on_rescued(reason: String) -> void:
	rescue(reason)


## Charges the fee, drops the cargo and tells the HUD.
func rescue(reason: String) -> void:
	rescues += 1
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	var paid := 0
	var lost := 0
	if jobs != null:
		paid = mini(FEE, jobs.wallet.credits)
		jobs.wallet.credits -= paid
		lost = jobs.lose_cargo()
	var why := "hit by a car" if reason == "car" else "after your fall"
	last_message = "Rescue drone %s: ¤%d%s" % [why, paid, (", %d orders lost" % lost) if lost > 0 else ""]
	_message_time = MESSAGE_SECONDS
	rescued.emit()


func _player() -> Player:
	return get_node_or_null(player_path) as Player if not player_path.is_empty() else null
