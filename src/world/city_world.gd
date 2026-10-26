class_name CityWorld
extends Node3D
## Streams the city around a focus node and keeps the floating origin near it
## (specs world-streaming, floating-origin, city-rendering).
##
## World content that must keep its absolute position across rebases (the camera, doorways,
## markers) joins ANCHORED_GROUP and must be a top-level world node (its parent must not
## itself be anchored), otherwise it would be shifted twice.

signal origin_shifted(delta: Vector3i)
signal chunk_loaded(chunk: Vector3i)
signal chunk_unloaded(chunk: Vector3i)

const ANCHORED_GROUP := &"world_anchored"
## Chunks this close (Chebyshev distance) to the player or the streaming focus are solid.
const COLLISION_RADIUS := 1

@export var config: CityConfig
@export var radius_h: int = 4
@export var radius_v: int = 3
@export var chunks_per_tick: int = 4
## Node whose position drives streaming and rebasing (usually the camera rig).
@export var focus_path: NodePath
## Optional: environment and light that follow the depth atmosphere.
@export var world_environment_path: NodePath
@export var sun_path: NodePath
## When false, tick() must be called manually (used by tests).
@export var auto_tick: bool = true

var layout: CityLayout
var pocket_layout: PocketLayout
var lighting: CityLighting
var planner: StreamingPlanner
var origin: FloatingOrigin
## When set, chunks stream around this node instead of the camera (e.g. the entrance doorway
## while the player is inside a pocket space). Rebasing always follows the camera.
var streaming_focus: Node3D = null

var _loaded: Dictionary = {}   # Vector3i -> ChunkView, or null for empty chunks


func _ready() -> void:
	if config == null:
		config = CityConfig.new()
	layout = CityLayout.new(config)
	pocket_layout = PocketLayout.new(layout)
	lighting = CityLighting.new(layout)
	planner = StreamingPlanner.for_config(config, radius_h, radius_v)
	planner.budget = chunks_per_tick
	origin = FloatingOrigin.for_config(config)
	_update_shader_roof()


func _process(_delta: float) -> void:
	if auto_tick:
		tick()


## One streaming step: rebase if needed, release far chunks, load up to the budget.
func tick() -> void:
	var focus := focus_node()
	if focus != null:
		var delta := origin.rebase_delta(focus.global_position)
		if delta != Vector3i.ZERO:
			rebase(delta)
	var focus_chunk := focus_chunk()
	for chunk in planner.to_unload(focus_chunk, _loaded):
		_unload(chunk)
	for chunk in planner.next_loads(focus_chunk, _loaded, chunks_per_tick):
		_load(chunk)
	_update_collision()
	_apply_atmosphere()


## Loads the chunks around the player and the streaming focus right now (ignoring the budget)
## and makes them solid — used after teleports so a walking player has ground at once.
func prime_focus() -> void:
	for node: Node3D in [focus_node(), streaming_node()]:
		if node == null:
			continue
		var centre := origin.absolute_chunk_of(node.global_position)
		for dx in range(-COLLISION_RADIUS, COLLISION_RADIUS + 1):
			for dy in range(-COLLISION_RADIUS, COLLISION_RADIUS + 1):
				for dz in range(-COLLISION_RADIUS, COLLISION_RADIUS + 1):
					var chunk := centre + Vector3i(dx, dy, dz)
					if chunk.y <= planner.top_chunk_y and not _loaded.has(chunk):
						_load(chunk)
	_update_collision()


## Chunks within COLLISION_RADIUS of the player or the streaming focus are solid; others are not.
func _update_collision() -> void:
	var centres: Array[Vector3i] = []
	for node: Node3D in [focus_node(), streaming_node()]:
		if node != null:
			centres.append(origin.absolute_chunk_of(node.global_position))
	for chunk: Vector3i in _loaded:
		var view := _loaded[chunk] as ChunkView
		if view == null:
			continue
		var near := false
		for centre in centres:
			var d := chunk - centre
			if maxi(absi(d.x), maxi(absi(d.y), absi(d.z))) <= COLLISION_RADIUS:
				near = true
		view.set_collision_enabled(near)


func focus_node() -> Node3D:
	return get_node_or_null(focus_path) as Node3D if not focus_path.is_empty() else null


## Node chunks are streamed around: the streaming focus if set, else the camera.
func streaming_node() -> Node3D:
	if streaming_focus != null and is_instance_valid(streaming_focus):
		return streaming_focus
	return focus_node()


func focus_chunk() -> Vector3i:
	var focus := streaming_node()
	return origin.absolute_chunk_of(focus.global_position if focus != null else Vector3.ZERO)


func is_streaming_complete() -> bool:
	return planner.next_loads(focus_chunk(), _loaded, 1).is_empty()


func loaded_chunks() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for chunk: Vector3i in _loaded:
		result.append(chunk)
	return result


func chunk_view(chunk: Vector3i) -> ChunkView:
	return _loaded.get(chunk) as ChunkView


## Light anchors (signs, lamps) of the loaded chunks within `chunk_radius` chunks of a scene position.
func light_anchors_near(scene_position: Vector3, chunk_radius: int = 1) -> Array[LightAnchor]:
	var centre := origin.absolute_chunk_of(scene_position)
	var result: Array[LightAnchor] = []
	for dx in range(-chunk_radius, chunk_radius + 1):
		for dy in range(-chunk_radius, chunk_radius + 1):
			for dz in range(-chunk_radius, chunk_radius + 1):
				var view := chunk_view(centre + Vector3i(dx, dy, dz))
				if view != null:
					result.append_array(view.light_anchors())
	return result


## Doorways of all loaded chunks.
func doorway_views() -> Array[DoorwayView]:
	var result: Array[DoorwayView] = []
	for chunk: Vector3i in _loaded:
		var view := _loaded[chunk] as ChunkView
		if view != null:
			result.append_array(view.doorway_views())
	return result


## Moves the origin by `delta` chunks and shifts all world content to match.
func rebase(delta: Vector3i) -> void:
	var shift := origin.apply_rebase(delta)
	for node in get_tree().get_nodes_in_group(ANCHORED_GROUP):
		var node3d := node as Node3D
		if node3d != null:
			node3d.global_position -= shift
		if node.has_method("on_origin_shifted"):
			node.call("on_origin_shifted", shift)
	_replace_chunk_views()
	_update_shader_roof()
	origin_shifted.emit(delta)


## Jumps the focus node to an absolute position (metres); the origin moves with it.
func teleport_focus(absolute: PackedFloat64Array) -> void:
	var focus := focus_node()
	var old_origin := origin.origin_chunk
	var local := origin.place_origin_at(absolute)
	var shift := Vector3(origin.origin_chunk - old_origin) * origin.chunk_size()
	for node in get_tree().get_nodes_in_group(ANCHORED_GROUP):
		var node3d := node as Node3D
		if node3d != null and node3d != focus:
			node3d.global_position -= shift
		if node.has_method("on_origin_shifted"):
			node.call("on_origin_shifted", shift)
	if focus != null:
		focus.global_position = local
		var body := focus as CharacterBody3D
		if body != null:
			body.velocity = Vector3.ZERO
	_replace_chunk_views()
	_update_shader_roof()
	origin_shifted.emit(origin.origin_chunk - old_origin)


## Depth of the streaming focus below the top of the roof layer, in layers (negative above it).
func focus_depth_layers() -> float:
	var focus := streaming_node()
	var absolute_y := origin.absolute_metres(focus.global_position if focus != null else Vector3.ZERO)[1]
	var roof_top := float(config.roof_layer + 1) * config.cell_size.y
	return (roof_top - absolute_y) / config.cell_size.y


func _load(chunk: Vector3i) -> void:
	var data := layout.generate_chunk(chunk)
	var view: ChunkView = null
	if not data.is_empty():
		view = ChunkView.new()
		add_child(view)
		var doorways := pocket_layout.doorways_for_blocks(data.blocks)
		var signs: Array[SignInfo] = []
		for block in data.blocks:
			var doorway: DoorwayInfo = null
			for candidate in doorways:
				if candidate.cell == block.cell:
					doorway = candidate
			signs.append_array(lighting.signs_of(block, doorway))
		var lamps: Array[LampInfo] = []
		for bridge in data.bridges:
			lamps.append_array(lighting.lamps_of(bridge))
		view.build(data, layout, origin, doorways, signs, lamps)
	_loaded[chunk] = view
	chunk_loaded.emit(chunk)


func _unload(chunk: Vector3i) -> void:
	var view := _loaded.get(chunk) as ChunkView
	if view != null:
		view.queue_free()
	_loaded.erase(chunk)
	chunk_unloaded.emit(chunk)


func _replace_chunk_views() -> void:
	for chunk: Vector3i in _loaded:
		var view := _loaded[chunk] as ChunkView
		if view != null:
			view.position = origin.scene_position_of_chunk(chunk)


func _update_shader_roof() -> void:
	var roof_bottom := origin.scene_position_of_cell(Vector3i(0, config.roof_layer, 0)).y
	ChunkView.block_material().set_shader_parameter("roof_bottom_y", roof_bottom)
	ChunkView.bridge_material().set_shader_parameter("roof_bottom_y", roof_bottom)


func _apply_atmosphere() -> void:
	var depth := focus_depth_layers()
	var env_node := get_node_or_null(world_environment_path) as WorldEnvironment \
			if not world_environment_path.is_empty() else null
	if env_node != null and env_node.environment != null:
		var env := env_node.environment
		var haze := Atmosphere.fog_color(depth)
		env.fog_light_color = haze
		env.fog_density = Atmosphere.fog_density(depth)
		env.ambient_light_energy = Atmosphere.ambient_energy(depth)
		var sky_material := env.sky.sky_material as ShaderMaterial if env.sky != null else null
		if sky_material != null:
			sky_material.set_shader_parameter("haze_color", haze)
			sky_material.set_shader_parameter("inside", clampf(depth / 3.0, 0.0, 1.0))
	var sun := get_node_or_null(sun_path) as DirectionalLight3D if not sun_path.is_empty() else null
	if sun != null:
		sun.light_energy = Atmosphere.light_energy(depth)
