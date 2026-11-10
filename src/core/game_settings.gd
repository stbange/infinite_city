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


func save(path: String = PATH) -> Error:
	var file := ConfigFile.new()
	file.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	file.set_value("game", "speed", game_speed)
	file.set_value("audio", "volume", volume)
	return file.save(path)


func load_from(path: String = PATH) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	mouse_sensitivity = clampf(float(file.get_value("input", "mouse_sensitivity", mouse_sensitivity)), 0.0005, 0.01)
	game_speed = clampf(float(file.get_value("game", "speed", game_speed)), 0.1, 10.0)
	volume = clampf(float(file.get_value("audio", "volume", volume)), 0.0, 1.0)


## Applies the settings to the running game.
func apply(player: Player, session: GameSession) -> void:
	if player != null:
		player.model.mouse_sensitivity = mouse_sensitivity
	if session != null:
		session.clock.speed = game_speed
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
