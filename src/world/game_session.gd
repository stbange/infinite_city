class_name GameSession
extends Node
## The running game (specs game-time, save-games): owns the clock, pushes the Light's brightness
## to the world, and saves and loads the session as versioned JSON in user://saves/.

const SAVE_VERSION := 2
const QUICK_SLOT := "quick"
const SAVE_DIR := "user://saves"

@export var world_path: NodePath
@export var player_path: NodePath
## When false the clock does not advance by itself (tests, screenshots).
@export var running: bool = true

var clock := GameClock.new_game()
## Outcome of the last quick save or load, for the HUD.
var last_message: String = ""
## Extra parts of the save: name -> [saver: Callable() -> Dictionary, loader: Callable(Dictionary)].
var _parts: Dictionary = {}


func register_part(part_name: String, saver: Callable, loader: Callable) -> void:
	_parts[part_name] = [saver, loader]


func _process(delta: float) -> void:
	if running:
		clock.advance_real(delta)
	refresh()


## F5 saves and F9 loads the quick slot (spec save-games / Saves keep the changed world).
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_F5:
			last_message = "Saved" if save_to_slot(QUICK_SLOT).is_empty() else "Save failed"
		KEY_F9:
			var problem := load_from_slot(QUICK_SLOT)
			last_message = "Loaded" if problem.is_empty() else problem


## Pushes the clock's Light level to the world.
func refresh() -> void:
	var world := _world()
	if world != null:
		world.daylight = clock.light_level()


func to_dict() -> Dictionary:
	var world := _world()
	var player := _player()
	var position: Array = [0.0, 0.0, 0.0]
	if world != null and player != null and world.origin != null:
		var absolute := world.origin.absolute_metres(player.global_position)
		position = [absolute[0], absolute[1], absolute[2]]
	var data := {
		"version": SAVE_VERSION,
		"seed": world.config.world_seed if world != null else 0,
		"minutes": clock.total_minutes,
		"player": {
			"position": position,
			"yaw": player.yaw if player != null else 0.0,
			"pitch": player.pitch if player != null else 0.0,
			"mode": player.mode if player != null else Player.Mode.WALK,
		},
	}
	for part_name: String in _parts:
		data[part_name] = (_parts[part_name][0] as Callable).call()
	return data


## Restores a saved session; returns "" on success or a message (and changes nothing).
func from_dict(data: Dictionary) -> String:
	var version := int(data.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		return "unsupported save version %d (this game reads up to %d)" % [version, SAVE_VERSION]
	var world := _world()
	var player := _player()
	if world == null or player == null:
		return "no world or player to restore into"
	var saved_seed := int(data.get("seed", world.config.world_seed))
	if saved_seed != world.config.world_seed:
		return "save is for seed %d, the world has seed %d" % [saved_seed, world.config.world_seed]
	var state: Dictionary = data.get("player", {})
	var position: Array = state.get("position", [0.0, 0.0, 0.0])
	clock.total_minutes = int(data.get("minutes", clock.total_minutes))
	player.set_mode(int(state.get("mode", Player.Mode.WALK)))
	world.teleport_focus(PackedFloat64Array([float(position[0]), float(position[1]), float(position[2])]))
	player.set_view(float(state.get("yaw", 0.0)), float(state.get("pitch", 0.0)))
	world.prime_focus()
	refresh()
	for part_name: String in _parts:
		if data.has(part_name):
			(_parts[part_name][1] as Callable).call(data[part_name])
	return ""


static func slot_path(slot: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot]


func save_to_slot(slot: String) -> String:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		return "cannot write %s: %s" % [slot_path(slot), error_string(FileAccess.get_open_error())]
	file.store_string(JSON.stringify(to_dict(), " "))
	return ""


func load_from_slot(slot: String) -> String:
	var text := FileAccess.get_file_as_string(slot_path(slot))
	if text.is_empty():
		return "no save in slot %s" % slot
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		return "save in slot %s is damaged" % slot
	return from_dict(data)


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _player() -> Player:
	return get_node_or_null(player_path) as Player if not player_path.is_empty() else null
