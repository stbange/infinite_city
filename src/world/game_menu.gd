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
var _text_scale: HSlider
var _colorblind: CheckBox
var _reduced: CheckBox
var _slots: VBoxContainer
var _keys: GridContainer
## Action waiting for its new key, or "".
var rebinding: String = ""
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
	_refresh_slots()
	_refresh_keys()
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


func apply_settings(sensitivity: float, speed: float, volume: float, text_scale: float = -1.0,
		colorblind: Variant = null, reduced: Variant = null) -> void:
	settings.mouse_sensitivity = sensitivity
	settings.game_speed = speed
	settings.volume = volume
	if text_scale > 0.0:
		settings.text_scale = text_scale
	if colorblind != null:
		settings.colorblind = bool(colorblind)
	if reduced != null:
		settings.reduced = bool(reduced)
	settings.save(settings_path)
	settings.apply(_player(), _session())


func _close() -> void:
	_root.visible = false
	apply_settings(_sensitivity.value / 10000.0, _speed.value, _volume.value / 100.0, _text_scale.value,
			_colorblind.button_pressed, _reduced.button_pressed)
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


func _input(event: InputEvent) -> void:
	if rebinding.is_empty() or not (event is InputEventKey) or not event.pressed:
		return
	press_key_for_rebinding((event as InputEventKey).physical_keycode)
	get_viewport().set_input_as_handled()


## Gives the action waiting for a key that key (spec release-candidate / Key rebinding).
func press_key_for_rebinding(keycode: int) -> void:
	if rebinding.is_empty():
		return
	if keycode != KEY_ESCAPE:
		settings.rebind(rebinding, keycode)
		settings.save(settings_path)
	rebinding = ""
	_refresh_keys()


## Loads a named slot; "" on success.
func load_slot(slot: String) -> String:
	var session := _session()
	if session == null:
		return "no session"
	var problem := session.load_from_slot(slot)
	if problem.is_empty():
		_close()
	return problem


## Saves into a new slot named after the date and time; returns the slot name or "".
func save_new_slot() -> String:
	var session := _session()
	if session == null:
		return ""
	var slot := GameSession.new_slot_name()
	if not session.save_to_slot(slot).is_empty():
		return ""
	_refresh_slots()
	return slot


func _refresh_slots() -> void:
	if _slots == null:
		return
	for child in _slots.get_children():
		child.queue_free()
	var slots := GameSession.list_slots()
	for i in mini(6, slots.size()):
		var entry: Dictionary = slots[i]
		var button := Button.new()
		button.text = "Load %s · %s" % [entry["slot"], entry["label"]]
		var slot: String = entry["slot"]
		button.pressed.connect(func() -> void: load_slot(slot))
		_slots.add_child(button)


func _refresh_keys() -> void:
	if _keys == null:
		return
	for child in _keys.get_children():
		child.queue_free()
	for action in GameSettings.REBINDABLE:
		var label := Label.new()
		label.text = action.replace("_", " ")
		_keys.add_child(label)
		var button := Button.new()
		button.text = "press a key…" if rebinding == action else _key_name(action)
		var which := action
		button.pressed.connect(func() -> void:
			rebinding = which
			_refresh_keys())
		_keys.add_child(button)


static func _key_name(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := event as InputEventKey
			return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != 0 else key.keycode)
	return "—"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_ESCAPE \
			and not is_open() and DisplayServer.get_name() != "headless":
		open()
		get_viewport().set_input_as_handled()


func _build() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.custom_minimum_size = Vector2(480, 0)
	_root.position = Vector2(-240, -360)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.1, 0.94)
	style.set_content_margin_all(22)
	_root.add_theme_stylebox_override("panel", style)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 680)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
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
	_text_scale = _slider(box, "Text size", 0.75, 2.0, settings.text_scale)
	_colorblind = CheckBox.new()
	_colorblind.text = "Colour-blind-safe faction colours"
	_colorblind.button_pressed = settings.colorblind
	box.add_child(_colorblind)
	_reduced = CheckBox.new()
	_reduced.text = "Reduced motion (still fog)"
	_reduced.button_pressed = settings.reduced
	box.add_child(_reduced)
	var keys_title := Label.new()
	keys_title.text = "Keys (click, then press a key)"
	box.add_child(keys_title)
	_keys = GridContainer.new()
	_keys.columns = 2
	box.add_child(_keys)
	var start := Button.new()
	start.text = "New game"
	start.pressed.connect(func() -> void: new_game())
	box.add_child(start)
	_continue = Button.new()
	_continue.text = "Continue (quick save)"
	_continue.pressed.connect(func() -> void: continue_game())
	box.add_child(_continue)
	var save := Button.new()
	save.text = "Save to a new slot"
	save.pressed.connect(func() -> void: save_new_slot())
	box.add_child(save)
	_slots = VBoxContainer.new()
	box.add_child(_slots)
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
