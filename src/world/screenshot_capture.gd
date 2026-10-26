class_name ScreenshotCapture
extends Node
## Headless visual check: with --screenshot=<file.png> on the user command line, waits until
## streaming is complete, saves the frame and quits.
## Optional: --pos=x,y,z (absolute metres)  --yaw=deg  --pitch=deg  --wait=frames
##           --doorway [--doorway-distance=m] [--doorway-height=m] [--inside] [--forward=m] [--look-back]
##             (stand before the doorway nearest the start, optionally step through it, move
##              forward into the room and turn around to look back at the city through the inner door)
##           --on-foot (walk instead of floating; the player falls onto whatever is below)
##           --no-hud  --scale=0.6 (resize)  out.jpg saves a JPEG instead of a PNG
## Usage: scripts/screenshot.sh out.png --pos=0,200,0 --pitch=-30

@export var world_path: NodePath
@export var camera_path: NodePath
@export var pocket_manager_path: NodePath

var _args: Dictionary = {}
var _frames_ready: int = 0
var _entered: bool = false


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


func _pockets() -> PocketManager:
	return get_node_or_null(pocket_manager_path) as PocketManager


func _process(_delta: float) -> void:
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
	_frames_ready += 1
	if _frames_ready < int(_args.get("wait", "8")):
		return
	var path: String = _args["screenshot"]
	var image := get_viewport().get_texture().get_image()
	if _args.has("scale"):
		var factor := float(_args["scale"])
		image.resize(roundi(image.get_width() * factor), roundi(image.get_height() * factor), Image.INTERPOLATE_LANCZOS)
	var error := image.save_jpg(path, 0.88) if path.ends_with(".jpg") else image.save_png(path)
	print("screenshot ", path, " -> ", error_string(error))
	get_tree().quit(0 if error == OK else 1)
