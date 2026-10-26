class_name InteriorLayout
extends RefCounted
## Floor plans and floors of blocks (spec block-interiors). Pure function of the seed and cell.

const FLOOR_HEIGHT := 4.0
const WALL := 0.3
const CORRIDOR_HALF := 1.25
const CORRIDOR_WIDTH := 2.5
## A row of units deeper than this gets a further corridor behind its first row.
const MAX_ROW_DEPTH := 24.0
const GRID := 4.0
const DOOR_WIDTH := 1.0
## Narrower remainders are merged into the neighbouring unit.
const MIN_UNIT_WIDTH := 6.0
## Stair core: two 1.6 m flights and a 0.2 m divider, 1.2 m landings around a 3 m run.
const STAIR_WIDTH := 1.6
const STAIR_DIVIDER := 0.2
const LANDING := 1.2
const STAIR_RUN := 3.0
const CORE_SIZE := Vector2(STAIR_WIDTH * 2.0 + STAIR_DIVIDER, LANDING * 2.0 + STAIR_RUN)
const SALT_PLAN := 51
const SALT_FLOOR := 52

var city: CityLayout
var pockets: PocketLayout


func _init(city_layout: CityLayout, pocket_layout: PocketLayout) -> void:
	city = city_layout
	pockets = pocket_layout


func plan_of(block: BlockInfo) -> InteriorPlan:
	var rng := CellRandom.new(DetHash.hash_cell(city.config.world_seed, SALT_PLAN, block.cell))
	var plan := InteriorPlan.new()
	plan.block = block
	plan.bottom = block.min_local().y
	plan.floors = roundi(block.size.y / FLOOR_HEIGHT)
	var lo := block.min_local()
	var hi := block.max_local()
	plan.inner = Rect2(lo.x + WALL, lo.z + WALL, hi.x - lo.x - 2.0 * WALL, hi.z - lo.z - 2.0 * WALL)
	var inner := plan.inner
	plan.corridors.append(Rect2(inner.position.x, -CORRIDOR_HALF, inner.size.x, CORRIDOR_WIDTH))
	plan.corridors.append(Rect2(-CORRIDOR_HALF, inner.position.y, CORRIDOR_WIDTH, inner.size.y))
	plan.core = Rect2(CORRIDOR_HALF, CORRIDOR_HALF, CORE_SIZE.x, CORE_SIZE.y)

	# Rows of units on both z sides, each facing a corridor on its side nearer the centre.
	var rows: Array[Array] = []  # [z0, z1, front_sign (+1: corridor on the high-z side), exterior]
	var start := CORRIDOR_HALF
	while inner.end.y - start > MAX_ROW_DEPTH:
		var g := ceilf((start + 9.0) / GRID) * GRID
		rows.append([start, g + 0.75, -1, false])
		plan.corridors.append(Rect2(inner.position.x, g + 0.75, inner.size.x, CORRIDOR_WIDTH))
		start = g + 0.75 + CORRIDOR_WIDTH
	rows.append([start, inner.end.y, -1, true])
	var first_plus_row := 0
	start = -CORRIDOR_HALF
	while start - inner.position.y > MAX_ROW_DEPTH:
		var g := floorf((start - 9.0) / GRID) * GRID
		rows.append([g - 0.75, start, 1, false])
		plan.corridors.append(Rect2(inner.position.x, g - 0.75 - CORRIDOR_WIDTH, inner.size.x, CORRIDOR_WIDTH))
		start = g - 0.75 - CORRIDOR_WIDTH
	rows.append([inner.position.y, start, 1, true])

	for r in rows.size():
		var row: Array = rows[r]
		var z0: float = row[0]
		var z1: float = row[1]
		var front: int = row[2]
		var exterior: bool = row[3]
		for span in _split_east(CORRIDOR_HALF, inner.end.x, rng):
			var is_core := r == first_plus_row and span.x == CORRIDOR_HALF
			_add_unit(plan, Rect2(span.x, z0, span.y - span.x, z1 - z0), front, exterior, is_core, rng)
		for span in _split_west(inner.position.x, -CORRIDOR_HALF, rng):
			_add_unit(plan, Rect2(span.x, z0, span.y - span.x, z1 - z0), front, exterior, false, rng)

	_add_entrances(plan, block)
	return plan


## Unit spans from x0 eastwards to x1, cut on grid lines, 2-3 bays wide (at least 6 m unless the
## whole span is narrower).
static func _split_east(x0: float, x1: float, rng: CellRandom) -> Array[Vector2]:
	var spans: Array[Vector2] = []
	var x := x0
	while x < x1 - 0.01:
		var first := ceilf((x + 6.0) / GRID) * GRID
		var e := first if rng.next_int(2) == 0 else first + GRID
		if x1 - e < MIN_UNIT_WIDTH:
			e = x1
		spans.append(Vector2(x, e))
		x = e
	return spans


## Unit spans from x1 westwards to x0, cut on grid lines, 2-3 bays wide.
static func _split_west(x0: float, x1: float, rng: CellRandom) -> Array[Vector2]:
	var spans: Array[Vector2] = []
	var x := x1
	while x > x0 + 0.01:
		var first := floorf((x - 6.0) / GRID) * GRID
		var e := first if rng.next_int(2) == 0 else first - GRID
		if e - x0 < MIN_UNIT_WIDTH:
			e = x0
		spans.append(Vector2(e, x))
		x = e
	return spans


## `front_sign` is +1 when the corridor is on the high-z side of the unit.
func _add_unit(plan: InteriorPlan, rect: Rect2, front_sign: int, exterior: bool, is_core: bool, rng: CellRandom) -> void:
	var door_x := rect.get_center().x
	var centres: Array[float] = []
	var c := ceilf((rect.position.x - 2.0) / GRID) * GRID + 2.0
	while c <= rect.end.x - 0.7:
		if c >= rect.position.x + 0.7:
			centres.append(c)
		c += GRID
	if not centres.is_empty():
		door_x = centres[rng.next_int(centres.size())]
	if is_core:
		door_x = rect.position.x + CORE_SIZE.x * 0.5
	plan.units.append(InteriorUnit.new(plan.units.size(), rect, front_sign, door_x, exterior, is_core))


func _add_entrances(plan: InteriorPlan, block: BlockInfo) -> void:
	var doorway := pockets.doorway_for_block(block)
	for bridge in city.bridges_of(block.cell):
		var sign := 1 if bridge.cell_a == block.cell else -1
		var floor := roundi((bridge.start.y - plan.bottom) / FLOOR_HEIGHT)
		var entrance := EntranceInfo.new(floor, bridge.axis, sign)
		var magic := doorway != null and doorway.on_bridge and doorway.face_axis == bridge.axis \
				and doorway.face_sign == sign
		if magic:
			plan.magic_ends.append(entrance)
		else:
			plan.entrances.append(entrance)


# --- Floors --------------------------------------------------------------------------------

const UNIT_WALL := 0.12
const CEILING := 3.7
const SLAB := 0.3
const WINDOW_SILL := 1.2
const WINDOW_SIZE := Vector2(1.6, 1.68)
const ENTRANCE_SIZE := Vector2(2.0, 3.0)
const ALCOVE_DEPTH := 1.3
const CORRIDOR_LIGHT_SPACING := 10.0
const CORRIDOR_COLORS: Array[Color] = [Color(0.2, 0.9, 1.0), Color(1.0, 0.25, 0.7), Color(0.65, 0.3, 1.0)]


func floor_of(plan: InteriorPlan, k: int) -> InteriorFloor:
	var block := plan.block
	var f := InteriorFloor.new()
	f.index = k
	f.y = plan.floor_y(k)
	var cell := block.cell
	_slab(plan, f, f.y, k > 0, f.slabs)
	_outer_walls(plan, f, k)
	_corridors(plan, f)
	_stairs(plan, f)
	for unit in plan.units:
		_unit_walls(plan, f, unit)
		if unit.is_core:
			continue
		var rng := CellRandom.new(DetHash.hash4(city.config.world_seed, SALT_FLOOR, cell.x, cell.y, cell.z, k * 1000 + unit.index))
		Furnisher.new(plan, f, unit, rng).furnish(block.kind)
	if k == plan.floors - 1:
		_slab(plan, f, plan.top(), true, f.roof)
		_hut(plan, f)
	return f


## A floor slab whose top is at `top`, optionally with the opening over the stair flights.
func _slab(plan: InteriorPlan, _f: InteriorFloor, top: float, with_opening: bool, into: Array[AABB]) -> void:
	var lo := plan.block.min_local()
	var hi := plan.block.max_local()
	var whole := Rect2(lo.x, lo.z, hi.x - lo.x, hi.z - lo.z)
	var pieces: Array[Rect2] = [whole]
	if with_opening:
		pieces = _subtract(whole, _stair_opening(plan))
	for piece in pieces:
		into.append(AABB(Vector3(piece.position.x, top - SLAB, piece.position.y), Vector3(piece.size.x, SLAB, piece.size.y)))


func _stair_opening(plan: InteriorPlan) -> Rect2:
	return Rect2(plan.core.position.x, plan.core.position.y + LANDING, plan.core.size.x, plan.core.size.y - LANDING)


## Rect minus a hole fully inside it: up to four pieces.
static func _subtract(r: Rect2, hole: Rect2) -> Array[Rect2]:
	var pieces: Array[Rect2] = []
	var h := hole.intersection(r)
	if not h.has_area():
		pieces.append(r)
		return pieces
	if h.position.y > r.position.y:
		pieces.append(Rect2(r.position.x, r.position.y, r.size.x, h.position.y - r.position.y))
	if r.end.y > h.end.y:
		pieces.append(Rect2(r.position.x, h.end.y, r.size.x, r.end.y - h.end.y))
	if h.position.x > r.position.x:
		pieces.append(Rect2(r.position.x, h.position.y, h.position.x - r.position.x, h.size.y))
	if r.end.x > h.end.x:
		pieces.append(Rect2(h.end.x, h.position.y, r.end.x - h.end.x, h.size.y))
	return pieces


func _outer_walls(plan: InteriorPlan, f: InteriorFloor, k: int) -> void:
	var lo := plan.block.min_local()
	var hi := plan.block.max_local()
	var y := f.y
	for axis: int in [Vector3.AXIS_X, Vector3.AXIS_Z]:
		var lat := Vector3.AXIS_Z if axis == Vector3.AXIS_X else Vector3.AXIS_X
		for sign: int in [1, -1]:
			var face: float = hi[axis] if sign > 0 else lo[axis]
			var inner_face := face - sign * WALL
			var lat_lo: float = lo[lat]
			var lat_hi: float = hi[lat]
			# Openings: [lateral from, lateral to, y from, y to, is_window]
			var openings: Array[Array] = []
			if plan.has_entrance(k, axis, sign):
				openings.append([-ENTRANCE_SIZE.x * 0.5, ENTRANCE_SIZE.x * 0.5, y, y + ENTRANCE_SIZE.y, false])
				f.entrance_openings.append(_face_box(axis, lat, face, inner_face, -ENTRANCE_SIZE.x * 0.5, ENTRANCE_SIZE.x * 0.5, y, y + ENTRANCE_SIZE.y))
			elif plan.is_magic_end(k, axis, sign):
				openings.append([-CORRIDOR_HALF, CORRIDOR_HALF, y, y + CEILING, false])
				var back := face - sign * ALCOVE_DEPTH
				f.walls.append(_face_box(axis, lat, back, back - sign * UNIT_WALL, -CORRIDOR_HALF, CORRIDOR_HALF, y, y + CEILING))
			var bay := ceilf(lat_lo / GRID) * GRID
			while bay + GRID <= lat_hi + 0.001:
				var w0 := bay + (GRID - WINDOW_SIZE.x) * 0.5
				var w1 := w0 + WINDOW_SIZE.x
				var corridor_end := absf(bay) < 0.001 or absf(bay + GRID) < 0.001
				if not corridor_end and w0 >= lat_lo + WALL + 0.1 and w1 <= lat_hi - WALL - 0.1:
					openings.append([w0, w1, y + WINDOW_SILL, y + WINDOW_SILL + WINDOW_SIZE.y, true])
					var mid := face - sign * 0.15
					f.glass.append(_face_box(axis, lat, mid + 0.03, mid - 0.03, w0, w1, y + WINDOW_SILL, y + WINDOW_SILL + WINDOW_SIZE.y))
				bay += GRID
			openings.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
			var cursor := lat_lo
			for opening in openings:
				var o0: float = opening[0]
				var o1: float = opening[1]
				var oy0: float = opening[2]
				var oy1: float = opening[3]
				if o0 > cursor:
					f.outer_walls.append(_face_box(axis, lat, face, inner_face, cursor, o0, y, y + GRID))
				if oy0 > y:
					f.outer_walls.append(_face_box(axis, lat, face, inner_face, o0, o1, y, oy0))
				if oy1 < y + GRID:
					f.outer_walls.append(_face_box(axis, lat, face, inner_face, o0, o1, oy1, y + GRID))
				cursor = o1
			if cursor < lat_hi:
				f.outer_walls.append(_face_box(axis, lat, face, inner_face, cursor, lat_hi, y, y + GRID))
			# Coarse shell: windows count as solid; entrances stay open.
			var shell_cursor := lat_lo
			for opening in openings:
				if opening[4]:
					continue
				var o0: float = opening[0]
				var o1: float = opening[1]
				f.shell.append(_face_box(axis, lat, face, inner_face, shell_cursor, o0, y, y + GRID))
				f.shell.append(_face_box(axis, lat, face, inner_face, o0, o1, opening[3], y + GRID))
				shell_cursor = o1
			f.shell.append(_face_box(axis, lat, face, inner_face, shell_cursor, lat_hi, y, y + GRID))


## A box between two planes perpendicular to `axis`, spanning [l0, l1] laterally and [y0, y1].
static func _face_box(axis: int, lat: int, a: float, b: float, l0: float, l1: float, y0: float, y1: float) -> AABB:
	var p := Vector3()
	var s := Vector3()
	p[axis] = minf(a, b)
	s[axis] = absf(a - b)
	p[lat] = l0
	s[lat] = l1 - l0
	p.y = y0
	s.y = y1 - y0
	return AABB(p, s)


func _corridors(plan: InteriorPlan, f: InteriorFloor) -> void:
	var color := CORRIDOR_COLORS[DetHash.hash_cell(city.config.world_seed, SALT_FLOOR + 1, plan.block.cell) % CORRIDOR_COLORS.size()]
	for corridor in plan.corridors:
		var along_x := corridor.size.x > corridor.size.y
		var length := corridor.size.x if along_x else corridor.size.y
		var pieces := maxi(1, ceili(length / CORRIDOR_LIGHT_SPACING))
		for i in pieces:
			var segment := Rect2(corridor.position.x + corridor.size.x * i / pieces, corridor.position.y, corridor.size.x / pieces, corridor.size.y) \
					if along_x else Rect2(corridor.position.x, corridor.position.y + corridor.size.y * i / pieces, corridor.size.x, corridor.size.y / pieces)
			var centre := segment.get_center()
			f.rooms.append(RoomInfo.new("Corridor", segment, -1, Vector3(centre.x, f.y + 3.2, centre.y), color, 0.5))
			var strip := Vector3(1.6, 0.05, 0.2) if along_x else Vector3(0.2, 0.05, 1.6)
			f.lamps.append(AABB(Vector3(centre.x - strip.x * 0.5, f.y + CEILING - 0.06, centre.y - strip.z * 0.5), strip))
			f.lamp_colors.append(color)


func _unit_walls(plan: InteriorPlan, f: InteriorFloor, unit: InteriorUnit) -> void:
	var r := unit.rect
	var y := f.y
	var t := UNIT_WALL
	# Front wall with the door (the stair core is open to its corridor).
	if not unit.is_core:
		var z0 := unit.front_z() - t if unit.front_sign > 0 else unit.front_z()
		var d0 := unit.door_x - DOOR_WIDTH * 0.5
		var d1 := unit.door_x + DOOR_WIDTH * 0.5
		f.walls.append(AABB(Vector3(r.position.x, y, z0), Vector3(d0 - r.position.x, CEILING, t)))
		f.walls.append(AABB(Vector3(d1, y, z0), Vector3(r.end.x - d1, CEILING, t)))
		f.walls.append(AABB(Vector3(d0, y + Furnisher.DOOR_HEIGHT, z0), Vector3(DOOR_WIDTH, CEILING - Furnisher.DOOR_HEIGHT, t)))
	if not unit.exterior:
		var zb := unit.back_z() if unit.front_sign > 0 else unit.back_z() - t
		f.walls.append(AABB(Vector3(r.position.x, y, zb), Vector3(r.size.x, CEILING, t)))
	if r.position.x > plan.inner.position.x + 0.01:
		f.walls.append(AABB(Vector3(r.position.x, y, r.position.y), Vector3(t, CEILING, r.size.y)))
	if r.end.x < plan.inner.end.x - 0.01:
		f.walls.append(AABB(Vector3(r.end.x - t, y, r.position.y), Vector3(t, CEILING, r.size.y)))


func _stairs(plan: InteriorPlan, f: InteriorFloor) -> void:
	var x0 := plan.core.position.x
	var z0 := plan.core.position.y
	var y := f.y
	var run_start := z0 + LANDING
	var run_end := run_start + STAIR_RUN
	var x1 := x0 + STAIR_WIDTH * 0.5
	var x2 := x0 + STAIR_WIDTH + STAIR_DIVIDER + STAIR_WIDTH * 0.5
	f.flights.append(StairFlight.new(Vector3(x1, y, run_start), Vector3(x1, y + 2.0, run_end), STAIR_WIDTH))
	f.flights.append(StairFlight.new(Vector3(x2, y + 2.0, run_end), Vector3(x2, y + 4.0, run_start), STAIR_WIDTH))
	# Back landing at mid height, divider between the flights, enclosure on the open sides.
	f.stair_solids.append(AABB(Vector3(x0, y + 2.0 - SLAB, run_end), Vector3(CORE_SIZE.x, SLAB, LANDING)))
	f.stair_solids.append(AABB(Vector3(x0 + STAIR_WIDTH, y, run_start), Vector3(STAIR_DIVIDER, CEILING, STAIR_RUN)))
	f.stair_solids.append(AABB(Vector3(x0 + CORE_SIZE.x, y, z0 + LANDING), Vector3(UNIT_WALL, CEILING, CORE_SIZE.y - LANDING)))
	f.stair_solids.append(AABB(Vector3(x0, y, z0 + CORE_SIZE.y), Vector3(CORE_SIZE.x + UNIT_WALL, CEILING, UNIT_WALL)))
	# Drawn steps (12 per flight).
	var steps := 12
	for i in steps:
		var rise := 2.0 * (i + 1) / steps
		var z_a := run_start + STAIR_RUN * i / steps
		f.steps.append(AABB(Vector3(x0, y, z_a), Vector3(STAIR_WIDTH, rise, STAIR_RUN / steps)))
		var z_b := run_end - STAIR_RUN * (i + 1) / steps
		f.steps.append(AABB(Vector3(x2 - STAIR_WIDTH * 0.5, y + 2.0 - SLAB, z_b), Vector3(STAIR_WIDTH, rise + SLAB, STAIR_RUN / steps)))
	var centre := plan.core.get_center()
	f.rooms.append(RoomInfo.new("Stairwell", plan.core, -1, Vector3(centre.x, y + 3.2, centre.y), Color(0.9, 0.85, 0.7), 0.6))
	f.lamps.append(AABB(Vector3(centre.x - 0.3, y + CEILING - 0.06, z0 + 0.3), Vector3(0.6, 0.05, 0.3)))
	f.lamp_colors.append(Color(0.9, 0.85, 0.7))


func _hut(plan: InteriorPlan, f: InteriorFloor) -> void:
	var x0 := plan.core.position.x
	var z0 := plan.core.position.y
	var w := CORE_SIZE.x
	var d := CORE_SIZE.y
	var top := plan.top()
	var h := 3.0
	var t := UNIT_WALL
	var door0 := x0 + STAIR_WIDTH + STAIR_DIVIDER
	f.hut.append(AABB(Vector3(x0 - t, top, z0), Vector3(t, h, d)))
	f.hut.append(AABB(Vector3(x0 + w, top, z0), Vector3(t, h, d)))
	f.hut.append(AABB(Vector3(x0 - t, top, z0 + d), Vector3(w + 2.0 * t, h, t)))
	f.hut.append(AABB(Vector3(x0 - t, top, z0 - t), Vector3(door0 - x0 + t, h, t)))
	f.hut.append(AABB(Vector3(door0, top + 2.4, z0 - t), Vector3(x0 + w + t - door0, h - 2.4, t)))
	f.hut.append(AABB(Vector3(x0 - t, top + h, z0 - t), Vector3(w + 2.0 * t, 0.2, d + 2.0 * t)))
