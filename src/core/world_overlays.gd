class_name WorldOverlays
extends RefCounted
## The event log applied to queries (spec event-log / Event log and overlays): bridge claims, food
## prices, deaths and moves on top of the generated baseline.

var claims: Dictionary = {}      # "cell|axis" -> gang key
var prices: Dictionary = {}      # "x,y,z" district -> factor
var dead: Dictionary = {}        # person key -> true
var moved: Dictionary = {}       # person key -> [x, y, z, floor, unit]
var moved_in: Dictionary = {}    # "x,y,z|floor|unit" -> Array of person keys
var blackouts: Dictionary = {}   # "x,y,z" district -> Array of days whose night is dark


static func bridge_key(bridge: BridgeInfo) -> String:
	return "%s|%d" % [bridge.cell_a, bridge.axis]


static func district_key(district: Vector3i) -> String:
	return "%d,%d,%d" % [district.x, district.y, district.z]


static func flat_key(cell: Vector3i, floor_index: int, unit: int) -> String:
	return "%d,%d,%d|%d|%d" % [cell.x, cell.y, cell.z, floor_index, unit]


func rebuild(log: EventLog) -> void:
	claims.clear()
	prices.clear()
	dead.clear()
	moved.clear()
	moved_in.clear()
	blackouts.clear()
	for event in log.events:
		apply(event)


func apply(event: Dictionary) -> void:
	match str(event.get("kind", "")):
		"bridge_taken":
			claims[str(event["bridge"])] = str(event["gang"])
		"price":
			prices[str(event["district"])] = float(event["factor"])
		"death":
			dead[str(event["person"])] = true
		"blackout":
			var key := str(event["district"])
			if not blackouts.has(key):
				blackouts[key] = []
			(blackouts[key] as Array).append(int(event["day"]))
		"moved":
			var key := str(event["person"])
			if moved.has(key):
				var old: Array = moved[key]
				var old_flat := flat_key(Vector3i(int(old[0]), int(old[1]), int(old[2])), int(old[3]), int(old[4]))
				(moved_in.get(old_flat, []) as Array).erase(key)
			var to: Array = event["to"]
			moved[key] = [int(to[0]), int(to[1]), int(to[2]), int(to[3]), int(to[4])]
			var flat := flat_key(Vector3i(int(to[0]), int(to[1]), int(to[2])), int(to[3]), int(to[4]))
			if not moved_in.has(flat):
				moved_in[flat] = []
			(moved_in[flat] as Array).append(key)


## The gang an event gave a bridge to, or "" when the baseline holds.
func claim_override(key: String) -> String:
	return str(claims.get(key, ""))


## Whether a district's lights are out at a game minute: from 19:00 of a blackout day to 06:00.
func is_dark(district: Vector3i, minute: int) -> bool:
	var days: Array = blackouts.get(district_key(district), [])
	if days.is_empty():
		return false
	var day := floori(float(minute) / GameClock.MINUTES_PER_DAY)
	var at := posmod(minute, GameClock.MINUTES_PER_DAY)
	return (days.has(day) and at >= 19 * 60) or (days.has(day - 1) and at < 6 * 60)


func price_factor(district: Vector3i) -> float:
	return float(prices.get(district_key(district), 1.0))


func is_dead(person_key: String) -> bool:
	return dead.has(person_key)


func has_moved(person_key: String) -> bool:
	return moved.has(person_key)


## Residents of a flat after the events: baseline minus the dead and moved-out, plus the moved-in.
func residents(population: Population, cell: Vector3i, floor_index: int, unit: int) -> Array[PersonInfo]:
	var result: Array[PersonInfo] = []
	for p in population.residents(cell, floor_index, unit):
		var key := p.id.key()
		if not dead.has(key) and not moved.has(key):
			result.append(p)
	for key: String in moved_in.get(flat_key(cell, floor_index, unit), []):
		if not dead.has(key):
			var p := population.person(PersonId.from_key(key))
			if p != null:
				result.append(p)
	return result


## Hash of claims, prices and residents over some cells (for replay tests).
func state_hash(population: Population, turf: TurfMap, cells: Array[Vector3i]) -> int:
	var parts := PackedStringArray()
	var layout := population.layout
	for cell in cells:
		for bridge in layout.bridges_of(cell):
			parts.append("%s=%s" % [bridge_key(bridge), turf.claim_of(bridge)])
		parts.append("p%s=%.3f" % [cell, price_factor(layout.district_of(cell))])
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		for flat in population.flats_of(block):
			for p in residents(population, cell, flat.x, flat.y):
				parts.append(p.id.key())
	return "|".join(parts).hash()
