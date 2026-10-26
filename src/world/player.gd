class_name Player
extends CharacterBody3D
## The player: a first-person body that walks (WalkModel, gravity, collision) or flies freely
## (FlightModel, no collision). Toggle with the `toggle_fly` action (spec on-foot-movement).
## The node origin is at the feet; the camera sits WalkModel.EYE_HEIGHT above.

enum Mode { WALK, FLY }

const CAPSULE_RADIUS := 0.35
const CAPSULE_HEIGHT := 1.8

@export var start_mode: Mode = Mode.WALK

var mode: int = Mode.WALK
var model := FlightModel.new()
var walk := WalkModel.new()
var fall_guard := FallGuard.new()
var yaw: float = 0.0
var pitch: float = 0.0
var camera: Camera3D
## When false, the scripted inputs below are used instead of the keyboard (tests, tools).
var input_enabled: bool = true
## Walking input: x = right, y = forward.
var move_input := Vector2.ZERO
## Flying input: x = right, y = up, z = back (forward is -z).
var fly_input := Vector3.ZERO
var wants_jump: bool = false
var wants_sprint: bool = false

var _shape: CollisionShape3D


func _ready() -> void:
	add_to_group(CityWorld.ANCHORED_GROUP)
	floor_max_angle = deg_to_rad(46.0)
	floor_snap_length = 0.4
	camera = get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
	camera.position = Vector3(0, WalkModel.EYE_HEIGHT, 0)
	_shape = get_node_or_null("Shape") as CollisionShape3D
	if _shape == null:
		_shape = CollisionShape3D.new()
		_shape.name = "Shape"
		var capsule := CapsuleShape3D.new()
		capsule.radius = CAPSULE_RADIUS
		capsule.height = CAPSULE_HEIGHT
		_shape.shape = capsule
		_shape.position = Vector3(0, CAPSULE_HEIGHT * 0.5, 0)
		add_child(_shape)
	set_mode(start_mode)
	set_view(yaw, pitch)


func set_mode(new_mode: int) -> void:
	mode = new_mode
	velocity = Vector3.ZERO
	if _shape != null:
		_shape.disabled = mode == Mode.FLY


func toggle_mode() -> void:
	set_mode(Mode.WALK if mode == Mode.FLY else Mode.FLY)


func set_view(p_yaw: float, p_pitch: float) -> void:
	yaw = p_yaw
	pitch = clampf(p_pitch, -FlightModel.MAX_PITCH, FlightModel.MAX_PITCH)
	rotation = Vector3(0.0, yaw, 0.0)
	if camera != null:
		camera.rotation = Vector3(pitch, 0.0, 0.0)


func eye_position() -> Vector3:
	return camera.global_position


## Called by CityWorld when the floating origin moves the world by -shift.
func on_origin_shifted(shift: Vector3) -> void:
	fall_guard.shift(-shift)


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
	if event.is_action_pressed("toggle_fly"):
		toggle_mode()
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if input_enabled:
		move_input = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_back", "move_forward"))
		fly_input = Vector3(Input.get_axis("move_left", "move_right"), Input.get_axis("move_down", "move_up"),
				Input.get_axis("move_forward", "move_back"))
		wants_jump = Input.is_action_just_pressed("move_up")
		wants_sprint = Input.is_action_pressed("boost")
	if mode == Mode.FLY:
		global_position += model.velocity(yaw, pitch, fly_input, wants_sprint) * delta
		return
	velocity = walk.step(velocity, yaw, move_input, wants_sprint, wants_jump, is_on_floor(), delta)
	wants_jump = false
	move_and_slide()
	if fall_guard.update(is_on_floor(), global_position, delta):
		global_position = fall_guard.reset_point()
		velocity = Vector3.ZERO
