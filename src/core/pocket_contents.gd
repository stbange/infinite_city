class_name PocketContents
extends RefCounted
## Furnishing of a pocket space, in interior coordinates (origin at the floor centre).

var pillars: Array[AABB] = []
var props: Array[AABB] = []
var prop_colors := PackedColorArray()
## Glowing ceiling panels.
var lights: Array[AABB] = []
## The landmark at the far side of the room.
var monument: AABB
