class_name LiveSimulation
extends RefCounted
## Daily ticks of the live area (spec live-simulation): gangs take bridges, food prices drift or
## climb with the shortage, residents die or move. Deterministic per seed, day and the log so far.

const SALT_LIVE := 200
static var TAKEOVER_CHANCE: float:
	get:
		return Economy.num("live", "takeover_chance")
const TAKEOVER_TRIES := 4
static var LIFE_CHANCE: float:
	get:
		return Economy.num("live", "life_chance")
static var DRIFT: float:
	get:
		return Economy.num("live", "drift")
static var PRICE_MIN: float:
	get:
		return Economy.num("live", "price_min")
static var PRICE_MAX: float:
	get:
		return Economy.num("live", "price_max")
static var SHORTAGE_PRICE: float:
	get:
		return Economy.num("live", "shortage_price")
const MIN_PRICE_CHANGE := 0.01


## Events of one day for some districts (not yet applied). `protected` holds person keys that
## never die or move by chance (the story's cast).
static func tick(population: Population, chronicle: CityChronicle, overlays: WorldOverlays, turf: TurfMap,
		day: int, districts: Array[Vector3i], shortage: bool, protected: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var minute := day * GameClock.MINUTES_PER_DAY + 4 * 60
	var sorted := districts.duplicate()
	sorted.sort()
	for district: Vector3i in sorted:
		var rng := CellRandom.new(DetHash.hash4(population.world_seed(), SALT_LIVE, district.x, district.y, district.z, day))
		_takeover(population, chronicle, turf, district, rng, minute, events)
		_price(overlays, district, rng, shortage, minute, events)
		_life(population, overlays, district, rng, minute, protected, events)
		if rng.next_float() < Economy.num("live", "blackout_chance"):
			events.append({"kind": "blackout", "minute": minute, "district": WorldOverlays.district_key(district), "day": day})
	return events


static func _takeover(population: Population, chronicle: CityChronicle, turf: TurfMap, district: Vector3i,
		rng: CellRandom, minute: int, events: Array[Dictionary]) -> void:
	var roll := rng.next_float()
	var size := population.layout.config.district_size
	var origin := population.layout.district_origin_cell(district)
	var tries: Array[Vector3i] = []
	for i in TAKEOVER_TRIES:
		tries.append(origin + Vector3i(rng.next_int(size), rng.next_int(size), rng.next_int(size)))
	var pick := rng.next_int(1000)
	if roll >= TAKEOVER_CHANCE or chronicle == null:
		return
	var gangs := _gangs_of(chronicle, district)
	if gangs.is_empty():
		return
	var gang := gangs[pick % gangs.size()]
	for cell in tries:
		for bridge in population.layout.bridges_of(cell):
			var current := turf.claim_of(bridge)
			if current != gang.key:
				events.append({"kind": "bridge_taken", "minute": minute, "bridge": WorldOverlays.bridge_key(bridge),
					"gang": gang.key, "from": current})
				return


## Gangs that can move in a district: its owner if a gang and the gangs living next to it, else any
## living gang of its Reach.
static func _gangs_of(chronicle: CityChronicle, district: Vector3i) -> Array[FactionInfo]:
	var gangs: Array[FactionInfo] = []
	var owner := chronicle.faction(chronicle.owner_of_district(district))
	if owner != null and owner.type == "gang":
		gangs.append(owner)
	var reach := chronicle.reach(CityChronicle.reach_of(district))
	var living: Array[FactionInfo] = []
	for f in reach.factions:
		if f.type != "gang" or not f.exists_at(CityHistory.PRESENT_YEAR):
			continue
		living.append(f)
		var d := f.home_district - district
		if maxi(absi(d.x), maxi(absi(d.y), absi(d.z))) <= 1 and not gangs.has(f):
			gangs.append(f)
	return gangs if not gangs.is_empty() else living


static func _price(overlays: WorldOverlays, district: Vector3i, rng: CellRandom, shortage: bool, minute: int,
		events: Array[Dictionary]) -> void:
	var u := rng.next_float()
	var current := overlays.price_factor(district)
	var next := clampf(current * (1.0 + (u - 0.5) * DRIFT), PRICE_MIN, PRICE_MAX)
	if shortage:
		next = current + (SHORTAGE_PRICE - current) * 0.5
	if absf(next - current) >= MIN_PRICE_CHANGE:
		events.append({"kind": "price", "minute": minute, "district": WorldOverlays.district_key(district),
			"factor": snappedf(next, 0.001)})


static func _life(population: Population, overlays: WorldOverlays, district: Vector3i, rng: CellRandom, minute: int,
		protected: Dictionary, events: Array[Dictionary]) -> void:
	var roll := rng.next_float()
	var layout := population.layout
	var cell := layout.district_origin_cell(district) + Vector3i(rng.next_int(population.layout.config.district_size), rng.next_int(population.layout.config.district_size), rng.next_int(population.layout.config.district_size))
	var pick := rng.next_int(1 << 20)
	var death_roll := rng.next_float()
	if roll >= LIFE_CHANCE:
		return
	var block := layout.block_at(cell)
	if block == null or block.kind != BlockTypes.Kind.HOUSING:
		return
	var people := population.block_people(block)
	if people.size() == 0:
		return
	var i := pick % people.size()
	var id: PersonId = people.ids[i]
	var key := id.key()
	if protected.has(key) or overlays.is_dead(key) or overlays.has_moved(key):
		return
	var age: int = people.ages[i]
	if death_roll < clampf((age - 50) / 40.0, 0.05, 0.9):
		events.append({"kind": "death", "minute": minute, "person": key})
		return
	var home := _vacant_flat(population, cell, overlays)
	if home.is_empty():
		return
	events.append({"kind": "moved", "minute": minute, "person": key, "to": home})


## The first vacant flat (no residents after the events) of the housing blocks around a cell.
static func _vacant_flat(population: Population, cell: Vector3i, overlays: WorldOverlays) -> Array:
	var layout := population.layout
	for r in 3:
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var c := cell + Vector3i(dx, 0, dz)
				var block := layout.block_at(c)
				if block == null or block.kind != BlockTypes.Kind.HOUSING:
					continue
				for flat in population.flats_of(block):
					if population.household(c, flat.x, flat.y).is_vacant() \
							and not overlays.moved_in.has(WorldOverlays.flat_key(c, flat.x, flat.y)):
						return [c.x, c.y, c.z, flat.x, flat.y]
	return []
