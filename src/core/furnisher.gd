class_name Furnisher
extends RefCounted
## Divides a unit into rooms and furnishes them (spec block-interiors / Flats, Themed units,
## Tidy furniture, Room light). Works in the unit's own frame: u runs along x from the unit's
## low-x side, v runs from the front (corridor) wall into the unit.

const CLEARANCE := 0.15
const ROOM_WALL := 0.1
const CEILING := 3.7
const CLEAR_DEPTH := 1.0
const DOOR_HEIGHT := 2.2
const ATTEMPTS := 40

enum Place { WALL, FREE }

const WOOD := Color(0.36, 0.24, 0.16)
const DARK := Color(0.11, 0.11, 0.13)
const WHITE := Color(0.82, 0.84, 0.87)
const STEEL := Color(0.45, 0.47, 0.5)
const FABRICS: Array[Color] = [Color(0.42, 0.16, 0.24), Color(0.16, 0.26, 0.4), Color(0.28, 0.28, 0.31), Color(0.2, 0.34, 0.3)]
const SCREEN := Color(0.3, 0.85, 1.0)
const NEON: Array[Color] = [Color(1.0, 0.25, 0.7), Color(0.2, 0.9, 1.0), Color(0.65, 0.3, 1.0), Color(1.0, 0.6, 0.2)]

var plan: InteriorPlan
var floor: InteriorFloor
var unit: InteriorUnit
var rng: CellRandom
var y: float
var _occupied: Array[Rect2] = []


func _init(p_plan: InteriorPlan, p_floor: InteriorFloor, p_unit: InteriorUnit, p_rng: CellRandom) -> void:
	plan = p_plan
	floor = p_floor
	unit = p_unit
	rng = p_rng
	y = p_floor.y


# --- Frame -------------------------------------------------------------------------------

func width() -> float:
	return unit.rect.size.x


func depth() -> float:
	return unit.rect.size.y


func door_u() -> float:
	return unit.door_x - unit.rect.position.x


## A rect of the unit frame as a rect of the x/z plane.
func xz(r: Rect2) -> Rect2:
	var x0 := unit.rect.position.x + r.position.x
	var za := unit.front_z() - unit.front_sign * r.position.y
	var zb := unit.front_z() - unit.front_sign * r.end.y
	return Rect2(x0, minf(za, zb), r.size.x, absf(zb - za))


func box(r: Rect2, h0: float, h1: float) -> AABB:
	var p := xz(r)
	return AABB(Vector3(p.position.x, y + h0, p.position.y), Vector3(p.size.x, h1 - h0, p.size.y))


# --- Rooms, walls, clear areas -------------------------------------------------------------

func add_room(room_name: String, r: Rect2, color: Color, energy: float) -> int:
	var area := xz(r)
	var centre := area.get_center()
	floor.rooms.append(RoomInfo.new(room_name, area, unit.index, Vector3(centre.x, y + 3.3, centre.y), color, energy))
	var lamp := Vector2(minf(1.2, area.size.x * 0.5), minf(0.6, area.size.y * 0.5))
	floor.lamps.append(AABB(Vector3(centre.x - lamp.x * 0.5, y + CEILING - 0.06, centre.y - lamp.y * 0.5),
			Vector3(lamp.x, 0.05, lamp.y)))
	floor.lamp_colors.append(color)
	return floor.rooms.size() - 1


func clear(r: Rect2) -> void:
	_occupied.append(r)
	floor.clear_areas.append(box(r, 0.0, DOOR_HEIGHT))


## A wall along u (constant v band) with an optional door gap centred at door_center.
func wall_u(u0: float, u1: float, v: float, door_center: float = -1.0, door_width: float = 0.9) -> void:
	var t := ROOM_WALL
	if door_center < 0.0:
		floor.walls.append(box(Rect2(u0, v - t * 0.5, u1 - u0, t), 0.0, CEILING))
		return
	var d0 := door_center - door_width * 0.5
	var d1 := door_center + door_width * 0.5
	if d0 > u0:
		floor.walls.append(box(Rect2(u0, v - t * 0.5, d0 - u0, t), 0.0, CEILING))
	if u1 > d1:
		floor.walls.append(box(Rect2(d1, v - t * 0.5, u1 - d1, t), 0.0, CEILING))
	floor.walls.append(box(Rect2(d0, v - t * 0.5, d1 - d0, t), DOOR_HEIGHT, CEILING))


## A wall along v (constant u band) with an optional door gap centred at door_center.
func wall_v(u: float, v0: float, v1: float, door_center: float = -1.0, door_width: float = 0.9) -> void:
	var t := ROOM_WALL
	if door_center < 0.0:
		floor.walls.append(box(Rect2(u - t * 0.5, v0, t, v1 - v0), 0.0, CEILING))
		return
	var d0 := door_center - door_width * 0.5
	var d1 := door_center + door_width * 0.5
	if d0 > v0:
		floor.walls.append(box(Rect2(u - t * 0.5, v0, t, d0 - v0), 0.0, CEILING))
	if v1 > d1:
		floor.walls.append(box(Rect2(u - t * 0.5, d1, t, v1 - d1), 0.0, CEILING))
	floor.walls.append(box(Rect2(u - t * 0.5, d0, t, d1 - d0), DOOR_HEIGHT, CEILING))


# --- Placement -----------------------------------------------------------------------------

func _free(r: Rect2) -> bool:
	for other in _occupied:
		if r.intersects(other):
			return false
	return true


## Places an item in a room; `size` is (length along the wall, depth) for WALL placement.
## Returns the placed rect in the unit frame, or an empty rect.
func place(room: int, room_rect: Rect2, size: Vector2, h0: float, h1: float, item_name: String, color: Color,
		glow: float = 0.0, mode: Place = Place.WALL) -> Rect2:
	var inner := room_rect.grow(-CLEARANCE)
	for attempt in ATTEMPTS:
		var r := Rect2()
		if mode == Place.WALL:
			var side := rng.next_int(4)
			var s := size if side < 2 else Vector2(size.y, size.x)
			if s.x > inner.size.x or s.y > inner.size.y:
				continue
			var u := rng.range_float(inner.position.x, inner.end.x - s.x)
			var v := rng.range_float(inner.position.y, inner.end.y - s.y)
			match side:
				0:
					v = inner.end.y - s.y
				1:
					v = inner.position.y
				2:
					u = inner.position.x
				_:
					u = inner.end.x - s.x
			r = Rect2(u, v, s.x, s.y)
		else:
			var s := size if rng.next_int(2) == 0 else Vector2(size.y, size.x)
			if s.x > inner.size.x or s.y > inner.size.y:
				continue
			r = Rect2(rng.range_float(inner.position.x, inner.end.x - s.x),
					rng.range_float(inner.position.y, inner.end.y - s.y), s.x, s.y)
		if not _free(r.grow(0.05)):
			continue
		_occupied.append(r)
		floor.add_item(box(r, h0, h1), item_name, color, glow, room)
		return r
	return Rect2()


## Places an item exactly at `r` if that spot is free; returns whether it was placed.
func put(room: int, r: Rect2, h0: float, h1: float, item_name: String, color: Color, glow: float = 0.0) -> bool:
	if not _free(r.grow(0.02)):
		return false
	_occupied.append(r)
	floor.add_item(box(r, h0, h1), item_name, color, glow, room)
	return true


## Puts an item on top of another one (no overlap check; it shares the base's footprint).
func stack(room: int, base: Rect2, size: Vector2, h0: float, h1: float, item_name: String, color: Color, glow: float = 0.0) -> void:
	var s := Vector2(minf(size.x, base.size.x), minf(size.y, base.size.y))
	var r := Rect2(base.get_center() - s * 0.5, s)
	floor.add_item(box(r, h0, h1), item_name, color, glow, room)


## Fills a room with a grid of cells; `fill` receives each free cell rect and places items in it.
func grid(room_rect: Rect2, cell: Vector2, margin: float, fill: Callable) -> int:
	var inner := room_rect.grow(-margin)
	var placed := 0
	var v := inner.position.y
	while v + cell.y <= inner.end.y + 0.001:
		var u := inner.position.x
		while u + cell.x <= inner.end.x + 0.001:
			var r := Rect2(u, v, cell.x, cell.y)
			if _free(r):
				if fill.call(r):
					placed += 1
			u += cell.x
		v += cell.y
	return placed


func occupy(r: Rect2) -> void:
	_occupied.append(r)


# --- Units ---------------------------------------------------------------------------------

func furnish(kind: int) -> void:
	clear(Rect2(door_u() - 0.5, 0.0, 1.0, CLEAR_DEPTH + CLEARANCE))
	if kind == BlockTypes.Kind.HOUSING:
		_flat()
	else:
		_themed(kind)


func _flat() -> void:
	var w := width()
	var d := depth()
	# The bathroom takes the front corner on the wider side of the entrance door.
	var left_space := door_u() - 0.5
	var right_space := w - door_u() - 0.5
	var bath_left := left_space >= right_space
	var bath_w := minf(2.4, (left_space if bath_left else right_space) - 0.05)
	var bath := Rect2(0.0 if bath_left else w - bath_w, 0.0, bath_w, 2.6)
	var kitchen := Rect2(bath_w if bath_left else 0.0, 0.0, w - bath_w, 2.6)
	var bath_room := add_room("Bathroom", bath, Color(0.75, 0.85, 1.0), 0.7)
	var kitchen_room := add_room("Kitchen", kitchen, Color(1.0, 0.78, 0.55), 0.9)
	var living_colors: Array[Color] = [Color(1.0, 0.62, 0.38), Color(1.0, 0.62, 0.38), Color(1.0, 0.62, 0.38),
			Color(1.0, 0.35, 0.75), Color(0.35, 0.8, 1.0)]
	var living_color := living_colors[rng.next_int(living_colors.size())]

	# Bathroom walls and door (the door opens into the back part of the flat).
	var bath_door := bath.get_center().x
	wall_v(bath.end.x if bath_left else bath.position.x, 0.0, 2.6)
	wall_u(bath.position.x, bath.end.x, 2.6, bath_door, 0.8)
	clear(Rect2(bath_door - 0.4, 2.6 - CLEAR_DEPTH, 0.8, CLEAR_DEPTH * 2.0))

	var living := Rect2(0.0, 2.6, w, d - 2.6)
	var bedroom := Rect2()
	var bed_room := -1
	if w >= 9.5 and d >= 7.5:
		var split := roundf((unit.rect.position.x + w * 0.5) / 4.0) * 4.0 - unit.rect.position.x
		split = clampf(split, 3.6, w - 3.6)
		var bedroom_left := rng.next_int(2) == 0
		bedroom = Rect2(0.0, 2.6, split, d - 2.6) if bedroom_left else Rect2(split, 2.6, w - split, d - 2.6)
		living = Rect2(split, 2.6, w - split, d - 2.6) if bedroom_left else Rect2(0.0, 2.6, split, d - 2.6)
		var door_v := minf(2.6 + 1.2, d - 0.8)
		wall_v(split, 2.6, d, door_v, 0.9)
		clear(Rect2(split - CLEAR_DEPTH, door_v - 0.45, CLEAR_DEPTH * 2.0, 0.9))
		# Front wall of the bedroom wherever the bathroom is not behind it.
		var lo := maxf(bedroom.position.x, 0.0)
		var hi := bedroom.end.x
		if bath.end.x > lo and bath.position.x < hi:
			if bath_left and hi > bath.end.x:
				wall_u(bath.end.x, hi, 2.6)
			elif not bath_left and bath.position.x > lo:
				wall_u(lo, bath.position.x, 2.6)
		else:
			wall_u(lo, hi, 2.6)
		var bed_color := Color(0.8, 0.45, 1.0) if rng.next_int(2) == 0 else Color(1.0, 0.55, 0.35)
		bed_room = add_room("Bedroom", bedroom, bed_color, 0.6)
	var living_room := add_room("Living room", living, living_color, 1.0)

	# Bathroom: shower and toilet in the front corners, sink on the outer side wall.
	var c := CLEARANCE
	var outer_u := bath.position.x + c if bath_left else bath.end.x - c
	var inner_u := bath.end.x - c if bath_left else bath.position.x + c
	var out_dir := 1.0 if bath_left else -1.0
	var shower := Rect2(minf(outer_u, outer_u + out_dir * 0.9), c, 0.9, 0.9)
	if not put(bath_room, shower, 0.0, 2.1, "shower", Color(0.55, 0.7, 0.8)):
		place(bath_room, bath, Vector2(0.8, 0.8), 0.0, 2.1, "shower", Color(0.55, 0.7, 0.8), 0.0, Place.FREE)
	var toilet := Rect2(minf(inner_u, inner_u - out_dir * 0.45), c, 0.45, 0.65)
	if not put(bath_room, toilet, 0.0, 0.45, "toilet", WHITE):
		place(bath_room, bath, Vector2(0.45, 0.6), 0.0, 0.45, "toilet", WHITE, 0.0, Place.FREE)
	var sink := Rect2(minf(outer_u, outer_u + out_dir * 0.45), 1.15, 0.45, 0.6)
	if put(bath_room, sink, 0.0, 0.85, "sink", WHITE):
		stack(bath_room, sink, Vector2(0.4, 0.05), 1.3, 1.36, "mirror_light", Color(0.8, 0.9, 1.0), 2.0)
	else:
		place(bath_room, bath, Vector2(0.5, 0.4), 0.0, 0.85, "sink", WHITE, 0.0, Place.FREE)

	# Bed: in the bedroom, else in the living room (studio).
	var sleep_room := bed_room if bed_room >= 0 else living_room
	var sleep_rect := bedroom if bed_room >= 0 else living
	var bed := place(sleep_room, sleep_rect, Vector2(1.6, 2.05), 0.0, 0.5, "bed", FABRICS[rng.next_int(FABRICS.size())])
	if not bed.has_area():
		bed = place(sleep_room, sleep_rect, Vector2(0.95, 2.0), 0.0, 0.5, "bed", FABRICS[0], 0.0, Place.FREE)
	if bed_room >= 0:
		var stand := place(bed_room, bedroom, Vector2(0.45, 0.4), 0.0, 0.5, "nightstand", WOOD)
		if stand.has_area():
			stack(bed_room, stand, Vector2(0.25, 0.25), 0.5, 0.85, "lamp", Color(1.0, 0.6, 0.35), 2.5)
		place(bed_room, bedroom, Vector2(1.8, 0.6), 0.0, 2.1, "wardrobe", DARK)

	# Kitchen counter (front strip first), fridge, table and seats.
	var counter := place(kitchen_room, kitchen, Vector2(2.4, 0.6), 0.0, 0.9, "counter", STEEL)
	if not counter.has_area():
		counter = place(kitchen_room, kitchen, Vector2(1.2, 0.6), 0.0, 0.9, "counter", STEEL)
	if not counter.has_area():
		counter = place(living_room, living, Vector2(1.2, 0.6), 0.0, 0.9, "counter", STEEL)
	place(kitchen_room, kitchen, Vector2(0.7, 0.7), 0.0, 1.9, "fridge", WHITE)
	var table := place(living_room, living, Vector2(1.2, 0.8), 0.0, 0.75, "table", WOOD, 0.0, Place.FREE)
	if not table.has_area():
		table = place(kitchen_room, kitchen, Vector2(0.8, 0.7), 0.0, 0.75, "table", WOOD, 0.0, Place.FREE)
	if not table.has_area():
		table = place(living_room, living, Vector2(0.7, 0.7), 0.0, 0.75, "table", WOOD, 0.0, Place.FREE)
	var table_room := living_room
	var table_rect := living
	for chair_index in 2:
		place(table_room, table_rect, Vector2(0.45, 0.45), 0.0, 0.9, "chair", DARK, 0.0, Place.FREE)
	var sofa := place(living_room, living, Vector2(2.0, 0.85), 0.0, 0.8, "sofa", FABRICS[rng.next_int(FABRICS.size())])
	if sofa.has_area():
		place(living_room, living, Vector2(1.0, 0.55), 0.0, 0.4, "coffee_table", WOOD, 0.0, Place.FREE)
	if not sofa.has_area():
		place(kitchen_room, kitchen, Vector2(0.45, 0.45), 0.0, 0.9, "chair", DARK, 0.0, Place.FREE)
	place(living_room, living, Vector2(1.4, 0.12), 0.9, 1.75, "screen", SCREEN, 1.6)
	place(living_room, living, Vector2(1.6, 0.4), 0.0, 1.8, "shelf", WOOD)
	place(living_room, living, Vector2(0.5, 0.5), 0.0, 1.2, "plant", Color(0.2, 0.45, 0.22))
	place(living_room, living, Vector2(2.0, 0.06), 2.8, 2.9, "neon_strip", NEON[rng.next_int(NEON.size())], 3.0)
	place(living_room, living, Vector2(0.35, 0.35), 0.0, 1.7, "floor_lamp", living_color, 2.0)


func _themed(kind: int) -> void:
	var room_rect := Rect2(0.0, 0.0, width(), depth())
	var names := {
		BlockTypes.Kind.OFFICE: "Office", BlockTypes.Kind.MARKET: "Shop", BlockTypes.Kind.FARM: "Grow room",
		BlockTypes.Kind.INDUSTRY: "Workshop", BlockTypes.Kind.PARK: "Garden", BlockTypes.Kind.HOSPITAL: "Ward",
		BlockTypes.Kind.FIRE_STATION: "Equipment room", BlockTypes.Kind.SECURITY: "Security office",
		BlockTypes.Kind.SCHOOL: "Classroom", BlockTypes.Kind.POWER_PLANT: "Generator hall",
		BlockTypes.Kind.WATER_WORKS: "Pump room", BlockTypes.Kind.TRANSIT_HUB: "Waiting hall",
	}
	var colors := {
		BlockTypes.Kind.OFFICE: Color(0.8, 0.9, 1.0), BlockTypes.Kind.MARKET: NEON[rng.next_int(NEON.size())],
		BlockTypes.Kind.FARM: Color(0.75, 0.3, 1.0), BlockTypes.Kind.INDUSTRY: Color(1.0, 0.7, 0.35),
		BlockTypes.Kind.PARK: Color(0.6, 1.0, 0.7), BlockTypes.Kind.HOSPITAL: Color(0.85, 0.95, 1.0),
		BlockTypes.Kind.SCHOOL: Color(0.95, 0.95, 0.88),
	}
	var color: Color = colors.get(kind, BlockTypes.color(kind).lerp(Color.WHITE, 0.4))
	var room := add_room(names.get(kind, "Hall"), room_rect, color, 1.2)
	match kind:
		BlockTypes.Kind.OFFICE:
			_office(room, room_rect)
		BlockTypes.Kind.MARKET:
			_shop(room, room_rect)
		BlockTypes.Kind.FARM:
			_farm(room, room_rect)
		BlockTypes.Kind.INDUSTRY:
			_workshop(room, room_rect)
		BlockTypes.Kind.PARK:
			_garden(room, room_rect)
		BlockTypes.Kind.HOSPITAL:
			_ward(room, room_rect)
		BlockTypes.Kind.SCHOOL:
			_classroom(room, room_rect)
		BlockTypes.Kind.FIRE_STATION, BlockTypes.Kind.SECURITY:
			_lockers(room, room_rect, BlockTypes.color(kind))
		BlockTypes.Kind.POWER_PLANT, BlockTypes.Kind.WATER_WORKS:
			_plant_room(room, room_rect, kind)
		_:
			_waiting_hall(room, room_rect)


func _desk(r: Rect2, room: int) -> bool:
	var desk := Rect2(r.position, Vector2(1.6, 0.8))
	var chair := Rect2(r.position + Vector2(0.55, 1.0), Vector2(0.5, 0.5))
	occupy(desk)
	occupy(chair)
	floor.add_item(box(desk, 0.0, 0.75), "desk", WOOD, 0.0, room)
	stack(room, Rect2(desk.position + Vector2(0.5, 0.0), Vector2(0.6, 0.06)), Vector2(0.6, 0.06), 0.75, 1.15, "screen", SCREEN, 1.8)
	floor.add_item(box(chair, 0.0, 0.9), "chair", DARK, 0.0, room)
	return true


func _office(room: int, r: Rect2) -> void:
	if grid(r, Vector2(2.2, 2.6), 0.4, _desk.bind(room)) == 0:
		place(room, r, Vector2(1.2, 0.6), 0.0, 0.75, "desk", WOOD)
	place(room, r, Vector2(0.5, 0.5), 0.0, 1.2, "plant", Color(0.2, 0.45, 0.22))


func _shop(room: int, r: Rect2) -> void:
	var shelves := 0
	for i in 6:
		var shelf := place(room, r, Vector2(1.8, 0.5), 0.0, 1.1, "shelf", DARK)
		if shelf.has_area():
			shelves += 1
			stack(room, shelf, Vector2(1.6, 0.35), 1.1, 1.45, "goods", NEON[rng.next_int(NEON.size())].lerp(WHITE, 0.4), 0.4)
	if shelves == 0:
		place(room, r, Vector2(0.9, 0.4), 0.0, 1.1, "shelf", DARK, 0.0, Place.FREE)
	var counter := place(room, r, Vector2(1.6, 0.6), 0.0, 1.0, "counter", STEEL, 0.0, Place.FREE)
	if counter.has_area():
		stack(room, counter, Vector2(0.4, 0.3), 1.0, 1.3, "register", SCREEN, 1.5)
	place(room, r, Vector2(2.4, 0.06), 2.7, 2.85, "neon_strip", NEON[rng.next_int(NEON.size())], 3.0)


func _rack(room: int, r: Rect2) -> bool:
	var rack := Rect2(r.position, Vector2(0.8, r.size.y - 0.2))
	occupy(rack)
	floor.add_item(box(rack, 0.0, 2.2), "grow_rack", Color(0.15, 0.3, 0.16), 0.6, room)
	stack(room, rack, Vector2(0.6, rack.size.y), 2.2, 2.3, "grow_light", Color(0.75, 0.3, 1.0), 3.0)
	return true


func _farm(room: int, r: Rect2) -> void:
	var inner := r.grow(-0.4)
	var lane := Rect2(inner.position.x, inner.position.y + CLEAR_DEPTH + 0.3, 1.8, inner.size.y - CLEAR_DEPTH - 0.3)
	var racks := 0
	while lane.end.x <= inner.end.x + 0.001 and lane.size.y > 1.5:
		if _free(Rect2(lane.position, Vector2(0.8, lane.size.y))):
			_rack(room, lane)
			racks += 1
		lane.position.x += 1.8
	if racks == 0:
		place(room, r, Vector2(0.8, 1.6), 0.0, 2.2, "grow_rack", Color(0.15, 0.3, 0.16), 0.6, Place.FREE)


func _machine(r: Rect2, room: int) -> bool:
	var m := Rect2(r.position, Vector2(2.0, 2.0))
	occupy(m)
	floor.add_item(box(m, 0.0, 2.4), "machine", STEEL, 0.0, room)
	stack(room, m, Vector2(0.6, 0.6), 2.4, 2.5, "status_light", Color(1.0, 0.55, 0.15), 2.5)
	return true


func _workshop(room: int, r: Rect2) -> void:
	if grid(r, Vector2(3.4, 3.4), 0.5, _machine.bind(room)) == 0:
		place(room, r, Vector2(1.2, 1.2), 0.0, 1.8, "machine", STEEL, 0.0, Place.FREE)
	for i in 3:
		place(room, r, Vector2(1.0, 1.0), 0.0, 1.0, "crate", WOOD, 0.0, Place.FREE)


func _planter(r: Rect2, room: int) -> bool:
	var p := Rect2(r.position, Vector2(1.6, 1.6))
	occupy(p)
	floor.add_item(box(p, 0.0, 0.6), "planter", Color(0.22, 0.2, 0.18), 0.0, room)
	stack(room, p, Vector2(1.5, 1.5), 0.6, 0.75, "greenery", Color(0.25, 0.6, 0.3), 0.3)
	if rng.next_int(2) == 0:
		stack(room, p, Vector2(0.3, 0.3), 0.75, 2.4, "trunk", WOOD)
		stack(room, p, Vector2(1.6, 1.6), 2.4, 3.4, "crown", Color(0.2, 0.5, 0.25), 0.2)
	return true


func _garden(room: int, r: Rect2) -> void:
	if grid(r, Vector2(3.0, 3.0), 0.6, _planter.bind(room)) == 0:
		place(room, r, Vector2(1.0, 1.0), 0.0, 0.6, "planter", Color(0.22, 0.2, 0.18), 0.0, Place.FREE)
	place(room, r, Vector2(1.8, 0.6), 0.0, 0.45, "bench", WOOD)


func _ward(room: int, r: Rect2) -> void:
	var beds := 0
	for i in 8:
		if place(room, r, Vector2(0.9, 2.0), 0.0, 0.6, "bed", WHITE).has_area():
			beds += 1
	if beds == 0:
		place(room, r, Vector2(0.8, 1.9), 0.0, 0.6, "bed", WHITE, 0.0, Place.FREE)
	place(room, r, Vector2(0.6, 0.4), 0.0, 1.0, "cart", STEEL, 0.0, Place.FREE)


func _school_desk(r: Rect2, room: int) -> bool:
	var desk := Rect2(r.position, Vector2(1.2, 0.6))
	var chair := Rect2(r.position + Vector2(0.35, 0.75), Vector2(0.45, 0.45))
	occupy(desk)
	occupy(chair)
	floor.add_item(box(desk, 0.0, 0.72), "desk", WOOD, 0.0, room)
	floor.add_item(box(chair, 0.0, 0.85), "chair", DARK, 0.0, room)
	return true


func _classroom(room: int, r: Rect2) -> void:
	var board := place(room, r, Vector2(3.0, 0.08), 0.9, 2.2, "board", Color(0.2, 0.75, 0.6), 1.2)
	if not board.has_area():
		place(room, r, Vector2(1.5, 0.08), 0.9, 2.2, "board", Color(0.2, 0.75, 0.6), 1.2)
	grid(r, Vector2(1.8, 1.8), 1.2, _school_desk.bind(room))


func _lockers(room: int, r: Rect2, color: Color) -> void:
	for i in 4:
		place(room, r, Vector2(1.8, 0.5), 0.0, 2.0, "locker", color.darkened(0.3))
	place(room, r, Vector2(1.8, 0.5), 0.0, 0.45, "bench", WOOD, 0.0, Place.FREE)
	var desk := place(room, r, Vector2(1.6, 0.8), 0.0, 0.75, "console", DARK)
	if desk.has_area():
		stack(room, desk, Vector2(1.4, 0.06), 0.75, 1.2, "screen", SCREEN, 1.8)


func _plant_room(room: int, r: Rect2, kind: int) -> void:
	var item := "generator" if kind == BlockTypes.Kind.POWER_PLANT else "tank"
	var glow_color := BlockTypes.color(kind)
	for i in 4:
		var big := place(room, r, Vector2(2.4, 2.4), 0.0, 3.0, item, STEEL, 0.0, Place.FREE)
		if big.has_area():
			stack(room, big, Vector2(2.4, 2.4), 3.0, 3.1, "glow_ring", glow_color, 2.5)
	var desk := place(room, r, Vector2(1.6, 0.8), 0.0, 0.75, "console", DARK)
	if desk.has_area():
		stack(room, desk, Vector2(1.4, 0.06), 0.75, 1.2, "screen", glow_color, 1.8)


func _waiting_hall(room: int, r: Rect2) -> void:
	for i in 5:
		place(room, r, Vector2(2.0, 0.6), 0.0, 0.45, "bench", STEEL, 0.0, Place.FREE)
	place(room, r, Vector2(2.0, 0.1), 1.6, 2.6, "screen", Color(1.0, 0.35, 0.8), 1.8)
