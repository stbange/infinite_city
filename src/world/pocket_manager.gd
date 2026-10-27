class_name PocketManager
extends Node3D
## Activates the pocket space of the nearest doorway, renders the live portal view and moves the
## camera through doorways (specs pocket-spaces, portal-traversal).
##
## Only one pocket space exists at a time. It is built 12 km above its doorway (out of sight of
## the city) and joins the world_anchored group so rebasing moves it with everything else.
## Crossings are detected at the player's eyes in door-local coordinates, which rebasing does
## not change; the body (feet), its view and its velocity are carried through the pair.

const ACTIVATION_RADIUS := 160.0
const POCKET_OFFSET := Vector3(0.0, 12000.0, 0.0)
## Visual layer bits: the city is drawn on layer 1, pocket spaces on layer 2.
const CITY_LAYERS := RenderLayers.CITY
## What the portal camera draws when it shows the city from inside a pocket space.
const OUTSIDE_LAYERS := RenderLayers.CITY | RenderLayers.INTERIOR | RenderLayers.FOG
const POCKET_LAYERS := RenderLayers.POCKET
const INTERIOR_GROUP := &"pocket_interior"

@export var world_path: NodePath
@export var camera_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var _active: DoorwayView
var _interior: PocketInterior
var _pocket: PocketSpaceInfo
var _inside: bool = false
var _viewport: SubViewport
var _portal_camera: Camera3D
var _prev_outer_local := Vector3.ZERO
var _prev_inner_local := Vector3.ZERO
var _tracking: bool = false


func _process(_delta: float) -> void:
	if auto_update:
		update()


func active_doorway() -> DoorwayView:
	return _active


func interior() -> PocketInterior:
	return _interior


func pocket_info() -> PocketSpaceInfo:
	return _pocket


func portal_camera() -> Camera3D:
	return _portal_camera


func is_inside() -> bool:
	return _inside


## One step: choose the active doorway, detect crossings, place the portal camera.
func update() -> void:
	var world := _world()
	var player := _player()
	if world == null or player == null or world.layout == null:
		return
	if _active != null and not is_instance_valid(_active):
		_inside = false
		world.streaming_focus = null
		_activate(null)
	var wanted := _active if _inside else nearest_doorway_view(ACTIVATION_RADIUS)
	if wanted != _active:
		_activate(wanted)
	if _active == null:
		return
	_check_crossing(player)
	_update_portal_camera(player)


## Nearest doorway (by opening centre) within `radius` metres of the camera, or null.
func nearest_doorway_view(radius: float) -> DoorwayView:
	var world := _world()
	var player := _player()
	if world == null or player == null:
		return null
	var position := player.eye_position()
	var centre_chunk := world.origin.absolute_chunk_of(position)
	var best: DoorwayView = null
	var best_distance := radius
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				var view := world.chunk_view(centre_chunk + Vector3i(dx, dy, dz))
				if view == null:
					continue
				for doorway_view in view.doorway_views():
					var opening := doorway_view.global_transform * Vector3(0, PortalMath.DOOR_SIZE.y * 0.5, 0)
					var distance := opening.distance_to(position)
					if distance <= best_distance:
						best_distance = distance
						best = doorway_view
	return best


## Puts the player's eyes `distance` m in front of a doorway, `height` m above its sill, facing it.
func place_camera_before(doorway: DoorwayInfo, distance: float, height: float = 3.0) -> void:
	var world := _world()
	var player := _player()
	var cell_size := world.config.cell_size
	var local := doorway.door * Vector3(0, height - WalkModel.EYE_HEIGHT, distance)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((doorway.cell[axis] + 0.5) * cell_size[axis] + local[axis])
	world.teleport_focus(absolute)
	var facing := -doorway.door.basis.z
	player.set_view(atan2(-facing.x, -facing.z), 0.0)
	_tracking = false


## Steps through the active doorway into its pocket space: the camera first moves onto the
## doorway (just behind its plane, inside the opening), then crosses as if it had flown through.
func enter() -> void:
	if _active == null or _inside:
		return
	var player := _player()
	var outer := _active.global_transform
	var eye := outer.affine_inverse() * player.eye_position()
	eye.x = clampf(eye.x, -PortalMath.DOOR_SIZE.x * 0.4, PortalMath.DOOR_SIZE.x * 0.4)
	eye.y = clampf(eye.y, 0.5, PortalMath.DOOR_SIZE.y - 0.5)
	eye.z = -0.5
	player.global_position += outer * eye - player.eye_position()
	_enter(player)
	_tracking = false


func _check_crossing(player: Player) -> void:
	var outer := _active.global_transform
	var inner := _interior.inner_door_global()
	var position := player.eye_position()
	if _tracking:
		if _inside:
			if PortalMath.crossed(inner, PortalMath.DOOR_SIZE, inner * _prev_inner_local, position):
				_leave(player)
		elif PortalMath.crossed(outer, PortalMath.DOOR_SIZE, outer * _prev_outer_local, position):
			_enter(player)
	position = player.eye_position()
	_prev_outer_local = outer.affine_inverse() * position
	_prev_inner_local = inner.affine_inverse() * position
	_tracking = true


func _enter(player: Player) -> void:
	_teleport(player, PortalMath.pair(_active.global_transform, _interior.inner_door_global()))
	_inside = true
	_world().streaming_focus = _active
	_active.set_portal_texture(null)
	_interior.door_view.set_portal_texture(_viewport.get_texture())


func _leave(player: Player) -> void:
	_teleport(player, PortalMath.pair(_interior.inner_door_global(), _active.global_transform))
	_inside = false
	_world().streaming_focus = null
	_interior.door_view.set_portal_texture(null)
	_active.set_portal_texture(_viewport.get_texture())


func _teleport(player: Player, mapping: Transform3D) -> void:
	var body := mapping * player.global_transform
	var eye := mapping * player.camera.global_transform
	player.global_position = body.origin
	player.velocity = mapping.basis * player.velocity
	var look := PortalMath.yaw_pitch_of(eye.basis)
	player.set_view(look.x, look.y)


func _activate(view: DoorwayView) -> void:
	if _active != null and is_instance_valid(_active):
		_active.set_portal_texture(null)
	if _interior != null:
		_interior.remove_from_group(INTERIOR_GROUP)
		_interior.remove_from_group(CityWorld.ANCHORED_GROUP)
		_interior.queue_free()
	_interior = null
	_pocket = null
	_active = view
	_tracking = false
	if view == null:
		if _viewport != null:
			_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_pocket = _world().pocket_layout.pocket_of(view.doorway)
	_interior = PocketInterior.new()
	add_child(_interior)
	_interior.build(_pocket, view.doorway)
	_interior.add_to_group(INTERIOR_GROUP)
	_interior.add_to_group(CityWorld.ANCHORED_GROUP)
	var outer := view.global_transform
	var inner := Transform3D(outer.basis, outer.origin + POCKET_OFFSET)
	_interior.global_transform = inner * _pocket.inner_door.affine_inverse()
	_ensure_viewport()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.set_portal_texture(_viewport.get_texture())


func _ensure_viewport() -> void:
	if _viewport != null:
		return
	_viewport = SubViewport.new()
	_viewport.name = "PortalViewport"
	_viewport.size = Vector2i(get_viewport().get_visible_rect().size)
	add_child(_viewport)
	_portal_camera = Camera3D.new()
	_portal_camera.name = "PortalCamera"
	_viewport.add_child(_portal_camera)
	_portal_camera.current = true


func _update_portal_camera(player: Player) -> void:
	var outer := _active.global_transform
	var inner := _interior.inner_door_global()
	var main_camera := player.camera
	var mapping := PortalMath.pair(inner, outer) if _inside else PortalMath.pair(outer, inner)
	var far_door := outer if _inside else inner
	_portal_camera.global_transform = mapping * main_camera.global_transform
	_portal_camera.cull_mask = OUTSIDE_LAYERS if _inside else POCKET_LAYERS
	_portal_camera.fov = main_camera.fov
	_portal_camera.far = main_camera.far
	_portal_camera.near = _clip_near(_portal_camera.global_transform, far_door, main_camera.near)
	var size := Vector2i(get_viewport().get_visible_rect().size)
	if _viewport.size != size:
		_viewport.size = size


## Near plane just short of the far door, so nothing between the portal camera and that door
## (for example the walls of the block it sits in) hides the view. Godot cameras have no oblique
## near plane; this is exact when looking straight at the door and conservative otherwise.
static func _clip_near(camera: Transform3D, door: Transform3D, fallback: float) -> float:
	var to_camera := camera.affine_inverse()
	var nearest := INF
	var half_width := PortalMath.DOOR_SIZE.x * 0.5
	for corner: Vector3 in [Vector3(-half_width, 0, 0), Vector3(half_width, 0, 0),
			Vector3(-half_width, PortalMath.DOOR_SIZE.y, 0), Vector3(half_width, PortalMath.DOOR_SIZE.y, 0)]:
		var depth := -(to_camera * (door * corner)).z
		if depth <= fallback:
			return fallback
		nearest = minf(nearest, depth)
	return maxf(fallback, nearest - 0.05)


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld


func _player() -> Player:
	return get_node_or_null(camera_path) as Player
