class_name CourierLamp
extends Node
## The courier's lamp (spec blackouts / Lamp): L switches it on and off; it drains its battery
## while on (a full charge lasts ten game hours) and recharges at the patron's counter.

const FULL_MINUTES := 600.0

@export var player_path: NodePath
@export var session_path: NodePath
@export var interaction_path: NodePath
@export var jobs_path: NodePath

var on: bool = false
var battery: float = 1.0
var last_message: String = ""
var _light: SpotLight3D
var _last_minute: float = -1.0
var _connected: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_L:
		toggle()


func toggle() -> void:
	if not on and battery <= 0.0:
		last_message = "The lamp's battery is empty — recharge at your patron's counter"
		return
	on = not on
	_sync()


func _process(_delta: float) -> void:
	update()


func update() -> void:
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	if not _connected:
		var interaction := get_node_or_null(interaction_path) as Interaction if not interaction_path.is_empty() else null
		if interaction != null:
			interaction.interacted.connect(_on_interacted)
		if session != null:
			session.register_part("lamp", func() -> Dictionary: return {"battery": battery, "on": on},
					func(data: Dictionary) -> void:
						battery = float(data.get("battery", 1.0))
						on = bool(data.get("on", false))
						_sync())
		_connected = true
	if session == null:
		return
	var now := session.clock.exact_minutes()
	if _last_minute >= 0.0 and on:
		battery = maxf(0.0, battery - (now - _last_minute) / FULL_MINUTES)
		if battery <= 0.0:
			on = false
			last_message = "The lamp flickers out"
	_last_minute = now
	_sync()


func recharge() -> void:
	battery = 1.0
	last_message = "Lamp recharged"


func _on_interacted(target: Dictionary) -> void:
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	if jobs == null or jobs.patron == null or target.get("kind") != "door":
		return
	var payload: Dictionary = target.get("payload", {})
	if payload.get("cell") == jobs.patron.cell and payload.get("floor") == jobs.patron.floor_index and payload.get("unit") == jobs.patron.unit:
		recharge()


func _sync() -> void:
	var player := get_node_or_null(player_path) as Player if not player_path.is_empty() else null
	if player == null or player.camera == null:
		return
	if _light == null:
		_light = SpotLight3D.new()
		_light.spot_range = 22.0
		_light.spot_angle = 32.0
		_light.light_energy = 3.0
		_light.light_color = Color(1.0, 0.92, 0.8)
		player.camera.add_child(_light)
	_light.visible = on
