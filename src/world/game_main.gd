extends Node3D
## Playable scene: starts the player on foot on a roof at the rim of the nearest shaft
## (or, in flight mode, above it).

@onready var world: CityWorld = $CityWorld
@onready var player: Player = $Player


func _ready() -> void:
	var spawn := SpawnFinder.find_on_foot(world.layout) if player.mode == Player.Mode.WALK \
			else SpawnFinder.find(world.layout)
	if spawn != null:
		var absolute := spawn.absolute_metres(world.config.cell_size)
		absolute[1] += 0.05
		world.teleport_focus(absolute)
		player.set_view(spawn.yaw, spawn.pitch)
	world.prime_focus()
