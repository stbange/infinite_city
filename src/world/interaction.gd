class_name Interaction
extends Node
## The interact key and its target (spec interaction). Providers list candidate targets near the
## player as {position, label, kind, payload}; the target is the nearest one within REACH of the
## eyes and MAX_ANGLE of the view. Pressing interact while walking emits `interacted`.

signal interacted(target: Dictionary)

const REACH := 2.5
const MAX_ANGLE := deg_to_rad(45.0)

@export var player_path: NodePath
@export var interiors_path: NodePath

var _target: Dictionary = {}
var _providers: Array[Callable] = []
var _label_hooks: Array[Callable] = []


func _process(_delta: float) -> void:
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	var player := _player()
	if player == null or not player.input_enabled or player.mode != Player.Mode.WALK:
		return
	if event.is_action_pressed("interact"):
		interact()


## Adds a label hook: Callable(target: Dictionary) -> String; a non-empty result replaces the label.
func add_label_hook(hook: Callable) -> void:
	_label_hooks.append(hook)


## Adds a provider: Callable(near: Vector3) -> Array[Dictionary].
func add_provider(provider: Callable) -> void:
	_providers.append(provider)


func target() -> Dictionary:
	return _target


func interact() -> void:
	if not _target.is_empty():
		interacted.emit(_target)


func refresh() -> void:
	_target = {}
	var player := _player()
	if player == null or player.camera == null:
		return
	var eye := player.eye_position()
	var forward := -player.camera.global_transform.basis.z
	var best := REACH
	for candidate in _candidates(eye):
		var offset: Vector3 = candidate["position"] - eye
		var distance := offset.length()
		if distance > best or distance < 0.01:
			continue
		if forward.angle_to(offset) > MAX_ANGLE:
			continue
		best = distance
		_target = candidate
	if not _target.is_empty():
		for hook in _label_hooks:
			var label: String = hook.call(_target)
			if not label.is_empty():
				_target["label"] = label


func _candidates(near: Vector3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var interiors := get_node_or_null(interiors_path) as InteriorManager if not interiors_path.is_empty() else null
	if interiors != null:
		result.append_array(interiors.door_targets(near))
	for provider in _providers:
		var extra: Array = provider.call(near)
		for item: Dictionary in extra:
			result.append(item)
	return result


func _player() -> Player:
	return get_node_or_null(player_path) as Player if not player_path.is_empty() else null
