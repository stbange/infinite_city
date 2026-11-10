class_name Routines
extends RefCounted
## Where every person is at any time (spec routines), as a pure function of person and day: home,
## the commute, the shift, an evening out, and sleep.

const SALT_ROUTINE := 160
const DAY := GameClock.MINUTES_PER_DAY
const COMMUTE := 20
const VENUE_WALK := 15
const VENUE_STAY := 120
const VENUE_CHANCE := 0.3
const VENUE_RANGE := 2
const SHIFT := 8 * 60
const SLEEP_FROM := 23 * 60
const SLEEP_TO := 7 * 60
const NIGHT_SLEEP_FROM := 8 * 60
const NIGHT_SLEEP_TO := 15 * 60

var population: Population
var layout: CityLayout
var _venue_cells: Dictionary = {}   # district -> Dictionary(cell -> PackedInt32Array of market indices)
var _venues: Dictionary = {}        # home cell -> Array[WorkplaceInfo]


func _init(p_population: Population) -> void:
	population = p_population
	layout = p_population.layout


func _hash(id: PersonId, salt: int, extra: int = 0) -> int:
	return DetHash.hash4(population.world_seed(), salt, id.district.x * 4096 + id.district.z, id.district.y, id.local, extra)


## The shift a person works on a day as Vector2i(start, end) in absolute minutes, or (-1, -1).
func shift_of(id: PersonId, day: int) -> Vector2i:
	var workplace := population.workplace_of(id)
	if workplace == null:
		return Vector2i(-1, -1)
	var h := _hash(id, SALT_ROUTINE)
	var weekday := posmod(day, 7)
	if weekday == h % 7 or weekday == (h % 7 + 1) % 7:
		return Vector2i(-1, -1)
	var span := workplace.closes - workplace.opens
	var start := workplace.opens
	var end := workplace.closes
	if span >= DAY:
		start = [6 * 60, 14 * 60, 22 * 60][(h >> 8) % 3]
		end = start + SHIFT
	elif span > 9 * 60:
		if (h >> 8) % 2 == 0:
			end = start + SHIFT
		else:
			start = end - SHIFT
	return Vector2i(day * DAY + start, day * DAY + end)


func _is_night(shift: Vector2i, day: int) -> bool:
	return shift.x >= 0 and shift.y > (day + 1) * DAY


func home_of(id: PersonId) -> NavPlace:
	return NavPlace.inside(id.cell(layout), id.floor_index(), id.unit_index())


## The day's segments in order, from the end of the previous day's night shift (if any) to the end
## of the day (or of a night shift running past midnight).
func day_plan(id: PersonId, day: int) -> Array[RoutineStep]:
	var home := home_of(id)
	var person := population.person(id)
	var start := day * DAY
	var before := shift_of(id, day - 1)
	if before.x >= 0 and before.y + COMMUTE > start:
		start = before.y + COMMUTE
	var away: Array[RoutineStep] = []
	var shift := shift_of(id, day)
	var night := _is_night(shift, day)
	var free_from := -1
	if shift.x >= 0:
		var w := population.workplace_of(id)
		var work := NavPlace.inside(w.cell, w.floor_index, w.unit)
		away.append(RoutineStep.new("commuting", work, shift.x - COMMUTE, shift.x, home))
		away.append(RoutineStep.new("working", work, shift.x, shift.y))
		away.append(RoutineStep.new("commuting", home, shift.y, shift.y + COMMUTE, work))
		free_from = shift.y + COMMUTE if not night else -1
	elif person != null and person.age >= 18:
		free_from = day * DAY + 15 * 60
	if free_from >= 0 and free_from <= day * DAY + 20 * 60 and person != null and person.age >= 18:
		var h := _hash(id, SALT_ROUTINE + 1, day)
		if DetHash.u01(h) < VENUE_CHANCE:
			var v := maxi(free_from + 30, day * DAY + 17 * 60) + (h >> 20) % 60
			if shift.x < 0:
				v = day * DAY + 15 * 60 + (h >> 20) % 180
			var venue := _pick_venue(id, v + VENUE_WALK, h)
			if venue != null:
				var place := NavPlace.inside(venue.cell, venue.floor_index, venue.unit)
				away.append(RoutineStep.new("going out", place, v, v + VENUE_WALK, home))
				away.append(RoutineStep.new("out", place, v + VENUE_WALK, v + VENUE_WALK + VENUE_STAY))
				away.append(RoutineStep.new("going home", home, v + VENUE_WALK + VENUE_STAY, v + 2 * VENUE_WALK + VENUE_STAY, place))
	away.sort_custom(func(a: RoutineStep, b: RoutineStep) -> bool: return a.start < b.start)
	var plan: Array[RoutineStep] = []
	var t := start
	for step in away:
		_fill_home(plan, home, t, step.start, day, night)
		plan.append(step)
		t = step.end
	_fill_home(plan, home, t, maxi(t, (day + 1) * DAY), day, night)
	return plan


## Home segments from a to b, asleep inside the sleep windows.
func _fill_home(plan: Array[RoutineStep], home: NavPlace, a: int, b: int, day: int, night: bool) -> void:
	if b <= a:
		return
	var cuts: Array[int] = []
	var windows: Array[Vector2i] = []
	if night:
		windows.append(Vector2i(day * DAY + NIGHT_SLEEP_FROM, day * DAY + NIGHT_SLEEP_TO))
	else:
		windows.append(Vector2i(day * DAY - DAY + SLEEP_FROM, day * DAY + SLEEP_TO))
		windows.append(Vector2i(day * DAY + SLEEP_FROM, day * DAY + DAY + SLEEP_TO))
	cuts.append(a)
	for w in windows:
		for edge: int in [w.x, w.y]:
			if edge > a and edge < b:
				cuts.append(edge)
	cuts.append(b)
	cuts.sort()
	for i in range(1, cuts.size()):
		var mid := (cuts[i - 1] + cuts[i]) / 2
		var asleep := false
		for w in windows:
			asleep = asleep or (mid >= w.x and mid < w.y)
		plan.append(RoutineStep.new("sleeping" if asleep else "at home", home, cuts[i - 1], cuts[i]))


## What a person does at an absolute game minute.
func at(id: PersonId, minute: int) -> RoutineStep:
	var day := floori(float(minute) / DAY)
	for d: int in [day, day - 1]:
		for step in day_plan(id, d):
			if step.contains(minute):
				return step
	return RoutineStep.new("at home", home_of(id), minute, minute + 1)


# --- Venues --------------------------------------------------------------------------------

## A food workplace within VENUE_RANGE cells of home, open for the whole stay, or null.
func _pick_venue(id: PersonId, arrive: int, h: int) -> WorkplaceInfo:
	var open: Array[WorkplaceInfo] = []
	var a := posmod(arrive, DAY)
	for w in venues_near(id.cell(layout), id.district):
		if w.is_open_at(a) and w.is_open_at(a + VENUE_STAY - 1):
			open.append(w)
	if open.is_empty():
		return null
	return open[(h >> 4) % open.size()]


## Active food workplaces of the home's district within VENUE_RANGE cells of a cell.
func venues_near(cell: Vector3i, district: Vector3i) -> Array[WorkplaceInfo]:
	if _venues.has(cell):
		return _venues[cell]
	var market := population.job_market(district)
	if not _venue_cells.has(district):
		var by_cell := {}
		for index in market.active_indices():
			var c := PersonId.new(district, market.local_of(index)).cell(layout)
			var list: PackedInt32Array = by_cell.get(c, PackedInt32Array())
			list.append(index)
			by_cell[c] = list
		_venue_cells[district] = by_cell
	var cells: Dictionary = _venue_cells[district]
	var result: Array[WorkplaceInfo] = []
	for dz in range(-VENUE_RANGE, VENUE_RANGE + 1):
		for dy in range(-VENUE_RANGE, VENUE_RANGE + 1):
			for dx in range(-VENUE_RANGE, VENUE_RANGE + 1):
				var c := cell + Vector3i(dx, dy, dz)
				if not cells.has(c):
					continue
				for index in (cells[c] as PackedInt32Array):
					var w := market.workplace(index)
					if w.is_food:
						result.append(w)
	if _venues.size() > 512:
		_venues.clear()
	_venues[cell] = result
	return result
