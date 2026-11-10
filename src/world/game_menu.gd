class_name GameMenu
extends CanvasLayer
## Main menu, courier creation and settings (spec game-menus). Shown at start in a normal run
## (not headless, not when taking a screenshot); the game waits while it is open. Esc reopens it.

signal started()

const PRONOUNS: Array[String] = ["she/her", "he/him", "they/them"]

@export var session_path: NodePath
@export var player_path: NodePath
@export var settings_path: String = GameSettings.PATH

var settings := GameSettings.new()
var profile := {"name": "Courier", "pronouns": "they/them"}
var _root: PanelContainer
var _name: LineEdit
var _pronouns: OptionButton
var _sensitivity: HSlider
var _speed: HSlider
var _volume: HSlider
var _continue: Button
var _registered: bool = false


func _ready() -> void:
	layer = 10
	settings.load_from(settings_path)
	_build()
	var session := _session()
	if session != null and not _registered:
		session.register_part("courier_profile", func() -> Dictionary: return profile.duplicate(),
				func(data: Dictionary) -> void: profile = data.duplicate())
		_registered = true
	var automatic := DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().size() > 0
	if automatic:
		_root.visible = false
		settings.apply(_player(), session)
	else:
		open()


func is_open() -> bool:
	return _root != null and _root.visible


func open() -> void:
	_root.visible = true
	_continue.disabled = not FileAccess.file_exists(GameSession.slot_path(GameSession.QUICK_SLOT))
	_set_paused(true)


## Starts a new game with the entered courier.
func new_game(courier_name: String = "", pronouns: String = "") -> void:
	if courier_name.is_empty():
		courier_name = _name.text.strip_edges()
	if pronouns.is_empty():
		pronouns = PRONOUNS[_pronouns.selected]
	profile = {"name": courier_name if not courier_name.is_empty() else "Courier", "pronouns": pronouns}
	_close()


## Loads the quick save; "" on success.
func continue_game() -> String:
	var session := _session()
	if session == null:
		return "no session"
	var problem := session.load_from_slot(GameSession.QUICK_SLOT)
	if problem.is_empty():
		_close()
	return problem


func apply_settings(sensitivity: float, speed: float, volume: float) -> void:
	settings.mouse_sensitivity = sensitivity
	settings.game_speed = speed
	settings.volume = volume
	settings.save(settings_path)
	settings.apply(_player(), _session())


func _close() -> void:
	_root.visible = false
	apply_settings(_sensitivity.value / 10000.0, _speed.value, _volume.value / 100.0)
	_set_paused(false)
	started.emit()


func _set_paused(paused: bool) -> void:
	var session := _session()
	var player := _player()
	if session != null:
		session.running = not paused
	if player != null:
		player.input_enabled = not paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_ESCAPE \
			and not is_open() and DisplayServer.get_name() != "headless":
		open()
		get_viewport().set_input_as_handled()


func _build() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.custom_minimum_size = Vector2(460, 0)
	_root.position = Vector2(-230, -220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.1, 0.94)
	style.set_content_margin_all(22)
	_root.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_root.add_child(box)
	var title := Label.new()
	title.text = "FOGLINE"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.95, 0.65, 0.25))
	box.add_child(title)
	_name = LineEdit.new()
	_name.placeholder_text = "Your courier's name"
	box.add_child(_name)
	_pronouns = OptionButton.new()
	for p in PRONOUNS:
		_pronouns.add_item(p)
	_pronouns.selected = 2
	box.add_child(_pronouns)
	_sensitivity = _slider(box, "Mouse sensitivity", 5.0, 100.0, settings.mouse_sensitivity * 10000.0)
	_speed = _slider(box, "Game minutes per second", 0.1, 5.0, settings.game_speed)
	_volume = _slider(box, "Volume", 0.0, 100.0, settings.volume * 100.0)
	var start := Button.new()
	start.text = "New game"
	start.pressed.connect(func() -> void: new_game())
	box.add_child(start)
	_continue = Button.new()
	_continue.text = "Continue (quick save)"
	_continue.pressed.connect(func() -> void: continue_game())
	box.add_child(_continue)
	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit)
	add_child(_root)


func _slider(box: VBoxContainer, text: String, lo: float, hi: float, value: float) -> HSlider:
	var label := Label.new()
	label.text = text
	box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = (hi - lo) / 100.0
	slider.value = value
	box.add_child(slider)
	return slider


func _session() -> GameSession:
	return get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null


func _player() -> Player:
	return get_node_or_null(player_path) as Player if not player_path.is_empty() else null
