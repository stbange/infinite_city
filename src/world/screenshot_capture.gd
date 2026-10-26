class_name ScreenshotCapture
extends Node
## Headless visual check: with --screenshot=<file.png> on the user command line, waits until
## streaming is complete, saves the frame and quits.
## Optional: --pos=x,y,z (absolute metres)  --yaw=deg  --pitch=deg  --wait=frames
##           --doorway [--doorway-distance=m] [--doorway-height=m] [--inside] [--forward=m] [--look-back]
##             (stand before the doorway nearest the start, optionally step through it, move
##              forward into the room and turn around to look back at the city through the inner door)
##           --on-foot (walk instead of floating; the player falls onto whatever is below)
##           --interior=entrance|corridor|flat|window|unit:KIND [--interior-distance=m] [--turn=deg]
##             (a block near the start: on the bridge before an entrance, in the corridor behind
##              it, in the door of a flat or of a unit of block kind KIND, or at a flat's window)
##           --no-hud  --scale=0.6 (resize)  out.jpg saves a JPEG instead of a PNG
## Usage: scripts/screenshot.sh out.png --pos=0,200,0 --pitch=-30

@export var world_path: NodePath
@export var camera_path: NodePath
@export var pocket_manager_path: NodePath
@export var interiors_path: NodePath

var _args: Dictionary = {}
var _frames_ready: int = 0
var _entered: bool = false
## Cell of the block whose interior must be ready before the frame is saved.
var _interior_cell := Vector3i.ZERO
var _wait_for_interior: bool = false
var _frames_total: int = 0


## A doorway near `near_cell` on the roof rows with open air in front of it: at least 25 m,
## preferably a long clear view (up to 160 m) so the city can be seen through it from inside.
static func showcase_doorway(world: CityWorld, near_cell: Vector3i, on_bridge: bool = false) -> DoorwayInfo:
	var best: DoorwayInfo = null
	var best_distance := INF
	var near_chunk := world.layout.chunk_of(near_cell)
	for dx in range(-3, 4):
		for dz in range(-3, 4):
			for chunk_y: int in [0, -1]:
				var chunk := Vector3i(near_chunk.x + dx, chunk_y, near_chunk.z + dz)
				for doorway in world.pocket_layout.doorways_in_chunk(chunk):
					if doorway.cell.y < world.config.roof_layer - 1 or (on_bridge and not doorway.on_bridge):
						continue
					var clear := _clear_view(world, doorway)
					if clear < 25.0:
						continue
					# Rank by closeness, strongly preferring a long clear view.
					var distance := Vector3(doorway.cell - near_cell).length() - clear * 0.1
					if distance < best_distance:
						best_distance = distance
						best = doorway
	return best


static func parse_args(args: PackedStringArray) -> Dictionary:
	var result := {}
	for arg in args:
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		if eq < 0:
			result[body] = ""
		else:
			result[body.substr(0, eq)] = body.substr(eq + 1)
	return result


static func parse_vector(text: String) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	for part in text.split(","):
		result.append(part.strip_edges().to_float())
	return result


## How far (m) the view straight out of a doorway stays clear of blocks, up to 160 m.
static func _clear_view(world: CityWorld, doorway: DoorwayInfo) -> float:
	var centre := (Vector3(doorway.cell) + Vector3(0.5, 0.5, 0.5)) * world.config.cell_size
	var clear := 0.0
	for metres: float in [5.0, 15.0, 25.0, 40.0, 60.0, 80.0, 100.0, 120.0, 140.0, 160.0]:
		var point := centre + doorway.door * Vector3(0, 3, metres)
		var block := world.layout.block_at(world.layout.cell_of_position(point))
		if block != null and world.layout.block_aabb(block).grow(2.0).has_point(point):
			return clear
		clear = metres
	return clear


func _ready() -> void:
	_args = parse_args(OS.get_cmdline_user_args())
	if not _args.has("screenshot"):
		set_process(false)
		return
	_apply_overrides.call_deferred()


func _apply_overrides() -> void:
	var world := get_node(world_path) as CityWorld
	var camera := get_node(camera_path) as Player
	camera.input_enabled = false
	# Scripted views fly (they float where they are put) unless --on-foot is given.
	camera.set_mode(Player.Mode.WALK if _args.has("on-foot") else Player.Mode.FLY)
	if _args.has("no-hud"):
		for hud in get_tree().get_nodes_in_group(&"hud"):
			(hud as CanvasLayer).visible = false
	world.chunks_per_tick = 64
	if _args.has("pos"):
		world.teleport_focus(parse_vector(_args["pos"]))
	var yaw := deg_to_rad(float(_args["yaw"])) if _args.has("yaw") else camera.yaw
	var pitch := deg_to_rad(float(_args["pitch"])) if _args.has("pitch") else camera.pitch
	camera.set_view(yaw, pitch)
	if _args.has("doorway"):
		var start := world.origin.absolute_cell_of(camera.global_position)
		var doorway := showcase_doorway(world, start, _args.has("on-foot"))
		if doorway != null:
			print("doorway at ", doorway.cell)
			_pockets().place_camera_before(doorway, float(_args.get("doorway-distance", "25")),
					float(_args.get("doorway-height", "3")))
	if _args.has("interior"):
		_place_in_interior(world, camera, _args["interior"])


## Puts the camera at an interior viewpoint of the nearest suitable block (see the header).
func _place_in_interior(world: CityWorld, camera: Player, mode: String) -> void:
	var interiors := InteriorLayout.new(world.layout, world.pocket_layout)
	var start := world.origin.absolute_cell_of(camera.global_position)
	var kind: int = BlockTypes.Kind.HOUSING
	if mode.begins_with("unit:"):
		kind = BlockTypes.Kind.get(mode.substr(5), BlockTypes.Kind.HOUSING)
	var cells: Array[Vector3i] = []
	for dx in range(-10, 11):
		for dy in range(-2, 2):
			for dz in range(-10, 11):
				cells.append(start + Vector3i(dx, dy, dz))
	cells.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return Vector3(a - start).length_squared() < Vector3(b - start).length_squared())
	var distance := float(_args.get("interior-distance", "8"))
	for cell in cells:
		var block := world.layout.block_at(cell)
		if block == null:
			continue
		var plan := interiors.plan_of(block)
		var local := Vector3.ZERO
		var facing := Vector3.ZERO
		if mode == "entrance" or mode == "corridor":
			if plan.entrances.is_empty():
				continue
			var entrance := plan.entrances[0]
			var normal := Vector3()
			normal[entrance.face_axis] = entrance.face_sign
			var face: float = block.max_local()[entrance.face_axis] if entrance.face_sign > 0 \
					else block.min_local()[entrance.face_axis]
			local[entrance.face_axis] = face + entrance.face_sign * (distance if mode == "entrance" else -1.5)
			local.y = plan.floor_y(entrance.floor_index) + 0.02
			facing = -normal
		else:
			if block.kind != kind or plan.floors < 3:
				continue
			var k := mini(2, plan.floors - 1)
			var f := interiors.floor_of(plan, k)
			var spot := _unit_viewpoint(plan, f, mode == "window")
			if spot.is_empty():
				continue
			local = Vector3(spot[0].x, plan.floor_y(k), spot[0].y)
			facing = Vector3(spot[1].x, 0, spot[1].y)
		var absolute := PackedFloat64Array()
		for axis in 3:
			absolute.append((cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
		world.teleport_focus(absolute)
		var yaw := atan2(-facing.x, -facing.z) + deg_to_rad(float(_args.get("turn", "0")))
		camera.set_view(yaw, deg_to_rad(float(_args.get("pitch", "0"))))
		world.prime_focus()
		_interior_cell = cell
		_wait_for_interior = mode != "entrance" or distance <= InteriorManager.ENTER_DISTANCE
		print("interior view in ", BlockTypes.display_name(block.kind), " at ", cell, " local ", local)
		return
	push_warning("no block for --interior=%s near %s" % [mode, start])


## [position, facing] (x/z, relative to the cell centre) in the largest room of a wide unit: in
## its front corner looking across to the far corner, or (window) before a free window bay
## looking out. Empty when the floor has no suitable unit.
static func _unit_viewpoint(plan: InteriorPlan, f: InteriorFloor, window: bool) -> Array[Vector2]:
	for unit in plan.units:
		if unit.is_core or unit.rect.size.x < 8.0 or (window and not unit.exterior):
			continue
		var best: RoomInfo = null
		for room in f.rooms:
			if room.unit_index == unit.index and (best == null or room.rect.get_area() > best.rect.get_area()):
				best = room
		if best == null:
			continue
		var r := best.rect.grow(-0.9)
		var back := -float(unit.front_sign)
		if window:
			var room_back := best.rect.end.y if back > 0 else best.rect.position.y
			if absf(room_back - unit.back_z()) > 0.6:
				continue
			var z := (unit.back_z() - back * 2.0)
			var bay := floorf(r.position.x / InteriorLayout.GRID) * InteriorLayout.GRID + InteriorLayout.GRID * 0.5
			while bay < r.end.x:
				var p := Vector2(bay, z)
				if bay > r.position.x and _free(f, p):
					return [p, Vector2(0, back)]
				bay += InteriorLayout.GRID
			continue
		var front_z := r.end.y if unit.front_sign > 0 else r.position.y
		var back_z := r.position.y if unit.front_sign > 0 else r.end.y
		for x: float in [r.position.x, r.end.x]:
			var p := Vector2(x, front_z)
			if _free(f, p):
				var far := Vector2(r.end.x if x == r.position.x else r.position.x, back_z)
				return [p, (far - p).normalized()]
	return []


## True when no furniture stands within 0.4 m of a point.
static func _free(f: InteriorFloor, p: Vector2) -> bool:
	for item in f.items:
		if item.size.y > 0.3 and Rect2(item.position.x, item.position.z, item.size.x, item.size.z).grow(0.4).has_point(p):
			return false
	return true


func _pockets() -> PocketManager:
	return get_node_or_null(pocket_manager_path) as PocketManager


func _process(_delta: float) -> void:
	_frames_total += 1
	if _frames_total > int(_args.get("max-frames", "1500")):
		push_error("screenshot: gave up waiting after %d frames" % _frames_total)
		get_tree().quit(2)
		return
	var world := get_node(world_path) as CityWorld
	if not world.is_streaming_complete():
		return
	if _args.has("inside") and not _entered and _pockets() != null and _pockets().active_doorway() != null:
		_pockets().enter()
		_entered = true
		var camera := get_node(camera_path) as Player
		if _args.has("forward"):
			var forward := camera.camera.global_transform.basis * Vector3(0, 0, -1)
			camera.global_position += forward * float(_args["forward"])
		if _args.has("look-back"):
			camera.set_view(camera.yaw + PI, camera.pitch)
		if _args.has("pitch"):
			camera.set_view(camera.yaw, deg_to_rad(float(_args["pitch"])))
		_frames_ready = 0
		return
	if _wait_for_interior:
		var interiors := get_node_or_null(interiors_path) as InteriorManager
		var view := interiors.view_for(_interior_cell) if interiors != null else null
		if view == null or not view.is_ready():
			return
	_frames_ready += 1
	if _frames_ready < int(_args.get("wait", "20" if _wait_for_interior else "8")):
		return
	var path: String = _args["screenshot"]
	var image := get_viewport().get_texture().get_image()
	if _args.has("scale"):
		var factor := float(_args["scale"])
		image.resize(roundi(image.get_width() * factor), roundi(image.get_height() * factor), Image.INTERPOLATE_LANCZOS)
	var error := image.save_jpg(path, 0.88) if path.ends_with(".jpg") else image.save_png(path)
	print("screenshot ", path, " -> ", error_string(error))
	get_tree().quit(0 if error == OK else 1)
