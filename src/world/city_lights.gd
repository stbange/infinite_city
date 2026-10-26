class_name CityLights
extends Node3D
## Real light sources near the player (spec city-lighting / Real light near the player).
## A fixed pool of OmniLight3Ds is re-targeted a few times per second to the nearest light
## anchors (signs, lamps) chosen by LightPool. The lights join the world_anchored group so a
## floating-origin rebase moves them with everything else.

const POOL_SIZE := 12
const REFRESH_SECONDS := 0.2
const FADE_SECONDS := 0.3

@export var world_path: NodePath
## Any Node3D whose position is the viewer (the fly camera or the walking player).
@export var viewer_path: NodePath
## Optional: the InteriorManager whose room lights join the pool.
@export var interiors_path: NodePath

var _lights: Array[OmniLight3D] = []
var _anchor_ids: Array[int] = []
var _target_energy: Array[float] = []
var _since_refresh: float = 0.0


func _ready() -> void:
	for i in POOL_SIZE:
		var light := OmniLight3D.new()
		light.name = "PoolLight%d" % i
		light.visible = false
		light.shadow_enabled = false
		light.light_cull_mask = RenderLayers.CITY | RenderLayers.INTERIOR
		light.omni_attenuation = 1.6
		add_child(light)
		light.add_to_group(CityWorld.ANCHORED_GROUP)
		_lights.append(light)
		_anchor_ids.append(-1)
		_target_energy.append(0.0)


func _process(delta: float) -> void:
	_since_refresh += delta
	if _since_refresh >= REFRESH_SECONDS:
		_since_refresh = 0.0
		refresh()
	for i in _lights.size():
		var light := _lights[i]
		if light.visible and light.light_energy < _target_energy[i]:
			light.light_energy = minf(_target_energy[i], light.light_energy + _target_energy[i] * delta / FADE_SECONDS)


## Re-targets the pool to the currently best anchors.
func refresh() -> void:
	var world := get_node_or_null(world_path) as CityWorld
	var viewer := get_node_or_null(viewer_path) as Node3D
	if world == null or viewer == null or world.origin == null:
		return
	var anchors := world.light_anchors_near(viewer.global_position)
	var interiors := get_node_or_null(interiors_path) as InteriorManager \
			if not interiors_path.is_empty() else null
	if interiors != null:
		anchors.append_array(interiors.light_anchors())
	var current: Array[int] = []
	for id in _anchor_ids:
		if id >= 0:
			current.append(id)
	var chosen := LightPool.select(anchors, viewer.global_position, POOL_SIZE, current)
	var chosen_by_id := {}
	for anchor in chosen:
		chosen_by_id[anchor.id] = anchor
	# Keep lights whose anchor is still chosen; free the others.
	for i in _lights.size():
		if _anchor_ids[i] >= 0 and chosen_by_id.has(_anchor_ids[i]):
			_place(i, chosen_by_id[_anchor_ids[i]], false)
			chosen_by_id.erase(_anchor_ids[i])
		else:
			_anchor_ids[i] = -1
			_lights[i].visible = false
	# Give free lights to newly chosen anchors.
	for anchor: LightAnchor in chosen_by_id.values():
		for i in _lights.size():
			if _anchor_ids[i] < 0:
				_anchor_ids[i] = anchor.id
				_place(i, anchor, true)
				break


func active_lights() -> Array[OmniLight3D]:
	var result: Array[OmniLight3D] = []
	for light in _lights:
		if light.visible:
			result.append(light)
	return result


func _place(index: int, anchor: LightAnchor, fresh: bool) -> void:
	var light := _lights[index]
	light.global_position = anchor.position
	light.light_color = anchor.color
	light.omni_range = anchor.light_range
	light.omni_attenuation = anchor.attenuation
	_target_energy[index] = anchor.energy
	if fresh:
		light.light_energy = 0.0
	light.visible = true
