extends Node3D
## Playable flythrough: puts the camera at the spawn point above the nearest shaft.

@onready var world: CityWorld = $CityWorld
@onready var fly_camera: FlyCamera = $FlyCamera


func _ready() -> void:
	var spawn := SpawnFinder.find(world.layout)
	if spawn != null:
		world.teleport_focus(spawn.absolute_metres(world.config.cell_size))
		fly_camera.set_view(spawn.yaw, spawn.pitch)
