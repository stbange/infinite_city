class_name GameSettings
extends RefCounted
## Player settings kept between sessions (spec game-menus / Settings): mouse sensitivity, game
## speed and volume, stored in a ConfigFile.

const PATH := "user://settings.cfg"

var mouse_sensitivity: float = 0.0025
## Game minutes per real second.
var game_speed: float = GameClock.DEFAULT_SPEED
## Master volume 0 … 1.
var volume: float = 0.8
## Size of on-screen text and panels (spec release-candidate / Accessibility).
var text_scale: float = 1.0
var colorblind: bool = false
## Still fog banks and no bloom.
var reduced: bool = false
## Action -> physical key code, for rebound actions.
var bindings: Dictionary = {}
## Actions the player may rebind.
const REBINDABLE: Array[String] = ["interact", "toggle_fly", "boost", "move_up", "move_forward", "move_back", "move_left", "move_right"]

## Read by systems that animate (the fog's wind); set by apply().
static var reduced_motion: bool = false


func save(path: String = PATH) -> Error:
	var file := ConfigFile.new()
	file.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	file.set_value("game", "speed", game_speed)
	file.set_value("audio", "volume", volume)
	file.set_value("access", "text_scale", text_scale)
	file.set_value("access", "colorblind", colorblind)
	file.set_value("access", "reduced_motion", reduced)
	file.set_value("input", "bindings", bindings)
	return file.save(path)


func load_from(path: String = PATH) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	mouse_sensitivity = clampf(float(file.get_value("input", "mouse_sensitivity", mouse_sensitivity)), 0.0005, 0.01)
	game_speed = clampf(float(file.get_value("game", "speed", game_speed)), 0.1, 10.0)
	volume = clampf(float(file.get_value("audio", "volume", volume)), 0.0, 1.0)
	text_scale = clampf(float(file.get_value("access", "text_scale", text_scale)), 0.75, 2.0)
	colorblind = bool(file.get_value("access", "colorblind", colorblind))
	reduced = bool(file.get_value("access", "reduced_motion", reduced))
	var saved: Variant = file.get_value("input", "bindings", {})
	bindings = (saved as Dictionary).duplicate() if saved is Dictionary else {}


## Applies the settings to the running game.
func apply(player: Player, session: GameSession) -> void:
	if player != null:
		player.model.mouse_sensitivity = mouse_sensitivity
	if session != null:
		session.clock.speed = game_speed
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	FactionPalette.colorblind = colorblind
	reduced_motion = reduced
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.content_scale_factor = text_scale
	for action: String in bindings:
		apply_binding(action, int(bindings[action]))


## Rebinds an action to a key and remembers it.
func rebind(action: String, keycode: int) -> bool:
	if not REBINDABLE.has(action) or not InputMap.has_action(action):
		return false
	bindings[action] = keycode
	apply_binding(action, keycode)
	return true


static func apply_binding(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var key := InputEventKey.new()
	key.physical_keycode = keycode as Key
	InputMap.action_add_event(action, key)
