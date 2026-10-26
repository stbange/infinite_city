class_name InteriorFloor
extends RefCounted
## Everything on one floor of a block, as boxes relative to the cell centre (spec block-interiors).

var index: int
## Walking surface height.
var y: float
## Floor slab pieces (with the opening over the stairs above floor 0).
var slabs: Array[AABB] = []
## Outer wall pieces around windows and entrances (drawn as façade, solid).
var outer_walls: Array[AABB] = []
## Coarse solid shell of the outer walls (one box per wall stretch, windows closed).
var shell: Array[AABB] = []
## Window panes.
var glass: Array[AABB] = []
## Entrance openings in the outer walls.
var entrance_openings: Array[AABB] = []
## Inner walls: units, rooms, the alcove behind a magic doorway.
var walls: Array[AABB] = []
## Stair core: landings, divider, enclosure (solid).
var stair_solids: Array[AABB] = []
## Drawn steps (collision uses the flights' ramps).
var steps: Array[AABB] = []
var flights: Array[StairFlight] = []
## Top floor only: roof slab pieces and the roof hut.
var roof: Array[AABB] = []
var hut: Array[AABB] = []
## Furniture.
var items: Array[AABB] = []
var item_names := PackedStringArray()
var item_colors := PackedColorArray()
## Emission strength per item (0 = matte).
var item_glow := PackedFloat32Array()
## Index into `rooms` for every item.
var item_rooms := PackedInt32Array()
## Ceiling lamps (drawn glowing, not solid).
var lamps: Array[AABB] = []
var lamp_colors := PackedColorArray()
## Areas in front of doors that furniture keeps free.
var clear_areas: Array[AABB] = []
var rooms: Array[RoomInfo] = []


func add_item(box: AABB, item_name: String, color: Color, glow: float, room: int) -> void:
	items.append(box)
	item_names.append(item_name)
	item_colors.append(color)
	item_glow.append(glow)
	item_rooms.append(room)


## Solid boxes of this floor apart from the shell (for collision near the player).
func solids() -> Array[AABB]:
	var result: Array[AABB] = []
	result.append_array(slabs)
	result.append_array(walls)
	result.append_array(stair_solids)
	result.append_array(roof)
	result.append_array(hut)
	for i in items.size():
		if items[i].size.y > 0.05:
			result.append(items[i])
	return result


## The room containing a point of the x/z plane, or null.
func room_at(point: Vector2) -> RoomInfo:
	for room in rooms:
		if room.rect.has_point(point):
			return room
	return null
