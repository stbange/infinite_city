class_name ScreenshotCapture
extends Node
## Headless visual check: with --screenshot=<file.png> on the user command line, waits until
## streaming is complete, saves the frame and quits.
## Optional: --pos=x,y,z (absolute metres)  --yaw=deg  --pitch=deg  --wait=frames
## Usage: scripts/screenshot.sh out.png --pos=0,200,0 --pitch=-30

@export var world_path: NodePath
@export var camera_path: NodePath

var _args: Dictionary = {}
var _frames_ready: int = 0


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


func _ready() -> void:
	_args = parse_args(OS.get_cmdline_user_args())
	if not _args.has("screenshot"):
		set_process(false)
		return
	_apply_overrides.call_deferred()


func _apply_overrides() -> void:
	var world := get_node(world_path) as CityWorld
	var camera := get_node(camera_path) as FlyCamera
	camera.input_enabled = false
	world.chunks_per_tick = 64
	if _args.has("pos"):
		world.teleport_focus(parse_vector(_args["pos"]))
	var yaw := deg_to_rad(float(_args["yaw"])) if _args.has("yaw") else camera.yaw
	var pitch := deg_to_rad(float(_args["pitch"])) if _args.has("pitch") else camera.pitch
	camera.set_view(yaw, pitch)


func _process(_delta: float) -> void:
	var world := get_node(world_path) as CityWorld
	if not world.is_streaming_complete():
		return
	_frames_ready += 1
	if _frames_ready < int(_args.get("wait", "8")):
		return
	var path: String = _args["screenshot"]
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("screenshot ", path, " -> ", error_string(error))
	get_tree().quit(0 if error == OK else 1)
