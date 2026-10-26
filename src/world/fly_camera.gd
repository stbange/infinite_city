class_name FlyCamera
extends Node3D
## Spectator camera rig: maps input to FlightModel (spec free-flight).
## Left click captures the mouse, Esc releases it, the mouse wheel changes cruise speed.

var model := FlightModel.new()
var yaw: float = 0.0
var pitch: float = 0.0
## Disabled by the screenshot tool so a scripted view stays put.
var input_enabled: bool = true
var camera: Camera3D


func _ready() -> void:
	add_to_group(CityWorld.ANCHORED_GROUP)
	camera = get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
	set_view(yaw, pitch)


func set_view(p_yaw: float, p_pitch: float) -> void:
	yaw = p_yaw
	pitch = clampf(p_pitch, -FlightModel.MAX_PITCH, FlightModel.MAX_PITCH)
	rotation = Vector3(pitch, yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			MOUSE_BUTTON_WHEEL_UP:
				model.cruise_speed = clampf(model.cruise_speed * 1.25, 5.0, 600.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				model.cruise_speed = clampf(model.cruise_speed / 1.25, 5.0, 600.0)
		return
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var look := model.apply_mouse(yaw, pitch, motion.relative)
		set_view(look.x, look.y)
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if not input_enabled:
		return
	var input := Vector3(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_down", "move_up"),
			Input.get_axis("move_forward", "move_back"))
	position += model.velocity(yaw, pitch, input, Input.is_action_pressed("boost")) * delta
