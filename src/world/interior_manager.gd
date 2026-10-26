class_name InteriorManager
extends Node3D
## Makes the blocks next to the player enterable (spec block-interiors / Entering blocks).
## Blocks within ENTER_DISTANCE get an InteriorView (at most MAX_ACTIVE, nearest first). While a
## view is being built the block's box stays; once ready, the box is hidden and stops colliding.
## Beyond RELEASE_DISTANCE the view is released and the box comes back.

const ENTER_DISTANCE := 12.0
const RELEASE_DISTANCE := 30.0
const MAX_ACTIVE := 2

@export var world_path: NodePath
@export var player_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var _layout: InteriorLayout
var _views: Dictionary = {}   # Vector3i -> InteriorView
var _connected_world: CityWorld


func _process(_delta: float) -> void:
	if auto_update:
		update()


func view_for(cell: Vector3i) -> InteriorView:
	return _views.get(cell) as InteriorView


func views() -> Array[InteriorView]:
	var result: Array[InteriorView] = []
	for view: InteriorView in _views.values():
		result.append(view)
	return result


func active_count() -> int:
	return _views.size()


## The ready view whose block contains a scene position, or null.
func view_at(scene_position: Vector3) -> InteriorView:
	for view: InteriorView in _views.values():
		if view.is_ready() and view.contains(scene_position):
			return view
	return null


## Room lights around the player in the entered blocks.
func light_anchors() -> Array[LightAnchor]:
	var result: Array[LightAnchor] = []
	var player := _player()
	if player == null:
		return result
	for view: InteriorView in _views.values():
		if view.is_ready():
			result.append_array(view.light_anchors(view.floor_index_at(player.global_position)))
	return result


## One step: choose the blocks to enter, release the others, build one floor of each new view,
## and keep collision around the player's floor.
func update() -> void:
	var world := _world()
	var player := _player()
	if world == null or player == null or world.layout == null:
		return
	_connect(world)
	if _layout == null:
		_layout = InteriorLayout.new(world.layout, world.pocket_layout)
	var wanted := _choose(world, player.global_position)
	for cell: Vector3i in _views.keys():
		if not wanted.has(cell):
			_release(world, cell)
	for block: BlockInfo in wanted.values():
		if not _views.has(block.cell):
			var view := InteriorView.new()
			view.setup(_layout.plan_of(block), _layout)
			add_child(view)
			view.global_position = world.origin.scene_position_of_cell_center(block.cell)
			_views[block.cell] = view
	for view: InteriorView in _views.values():
		var player_floor := view.floor_index_at(player.global_position)
		if not view.is_ready():
			view.build_step(player_floor)
		if view.is_ready():
			var chunk := world.chunk_view(world.layout.chunk_of(view.cell))
			if chunk != null and not chunk.is_block_hidden(view.cell):
				chunk.set_block_hidden(view.cell, true)
			view.set_collision_floors(player_floor)


## Blocks to keep or enter, by cell: nearest first, at most MAX_ACTIVE.
func _choose(world: CityWorld, player_position: Vector3) -> Dictionary:
	var centre := world.origin.absolute_cell_of(player_position)
	var candidates: Array[Array] = []   # [distance, block]
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				var block := world.layout.block_at(centre + Vector3i(dx, dy, dz))
				if block == null or world.chunk_view(world.layout.chunk_of(block.cell)) == null:
					continue
				var local := player_position - world.origin.scene_position_of_cell_center(block.cell)
				var distance := InteriorView.box_distance(AABB(block.min_local(), block.size), local)
				var limit := RELEASE_DISTANCE if _views.has(block.cell) else ENTER_DISTANCE
				if distance <= limit:
					candidates.append([distance, block])
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var wanted := {}
	for candidate in candidates:
		if wanted.size() >= MAX_ACTIVE:
			break
		var block: BlockInfo = candidate[1]
		wanted[block.cell] = block
	return wanted


func _release(world: CityWorld, cell: Vector3i) -> void:
	var view: InteriorView = _views[cell]
	_views.erase(cell)
	var chunk := world.chunk_view(world.layout.chunk_of(cell))
	if chunk != null:
		chunk.set_block_hidden(cell, false)
	view.queue_free()


func _connect(world: CityWorld) -> void:
	if _connected_world == world:
		return
	_connected_world = world
	world.origin_shifted.connect(_on_origin_shifted)


func _on_origin_shifted(_delta: Vector3i) -> void:
	var world := _world()
	for view: InteriorView in _views.values():
		view.global_position = world.origin.scene_position_of_cell_center(view.cell)


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _player() -> Player:
	return get_node_or_null(player_path) as Player if not player_path.is_empty() else null
