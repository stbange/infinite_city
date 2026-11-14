class_name Ambience
extends Node
## Procedural city ambience (spec game-menus / Ambience): a low hum with filtered noise, louder and
## darker below the fogline, generated on the fly (no audio files).

const MIX_RATE := 22050.0

@export var world_path: NodePath
@export var encounters_path: NodePath
@export var panel_path: NodePath

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _noise: float = 0.0
var _seed: int = 12345
## Loudness 0 … 1 and brightness (filter) 0 … 1 by depth.
var loudness: float = 0.3
var brightness: float = 0.5
## Music layers (spec release-candidate / Sound): a pulse in chases, a drone under scenes.
var pulse: float = 0.0
var drone: float = 0.0
var _beat: float = 0.0
var _chord: float = 0.0


func _ready() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.3
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.volume_db = -14.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	var world := get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null
	if world != null:
		var levels := levels_for(world.focus_depth_layers())
		loudness = levels.x
		brightness = levels.y
	var encounters := get_node_or_null(encounters_path) as EncounterDirector if not encounters_path.is_empty() else null
	var panel := get_node_or_null(panel_path) as DialoguePanel if not panel_path.is_empty() else null
	var music := music_for(encounters != null and encounters.state == EncounterDirector.State.CHASE,
			panel != null and panel.is_open())
	pulse = lerpf(pulse, music.x, 0.05)
	drone = lerpf(drone, music.y, 0.02)
	fill()


## (pulse, drone) levels: a driving pulse while chased, a soft chord while a scene is open.
static func music_for(chased: bool, scene: bool) -> Vector2:
	return Vector2(0.7 if chased else 0.0, 0.4 if scene and not chased else 0.0)


## (loudness, brightness) at a depth in layers below the roof: louder and darker deeper down.
static func levels_for(depth_layers: float) -> Vector2:
	var depth := clampf(depth_layers / 10.0, 0.0, 1.0)
	return Vector2(lerpf(0.25, 0.6, depth), lerpf(0.6, 0.15, depth))


## Pushes as many frames as the buffer takes; returns how many were pushed.
func fill() -> int:
	if _playback == null:
		return 0
	var frames := _playback.get_frames_available()
	for i in frames:
		_phase = fmod(_phase + 55.0 / MIX_RATE, 1.0)
		_seed = (_seed * 1103515245 + 12345) & 0x7fffffff
		var white := float(_seed) / float(0x7fffffff) * 2.0 - 1.0
		_noise += (white - _noise) * brightness * 0.2
		var sample := (sin(_phase * TAU) * 0.35 + _noise * 0.65) * loudness
		_beat = fmod(_beat + 2.2 / MIX_RATE, 1.0)
		_chord = fmod(_chord + 1.0 / MIX_RATE, 1000.0)
		if pulse > 0.001:
			sample += sin(TAU * 60.0 * _beat) * exp(-_beat * 9.0) * pulse
		if drone > 0.001:
			sample += (sin(TAU * 110.0 * _chord) + sin(TAU * 165.0 * _chord) * 0.6) * 0.15 * drone
		_playback.push_frame(Vector2(sample, sample))
	return frames
