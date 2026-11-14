class_name CourierBoard
extends RefCounted
## Food orders offered at a patron's counter (spec courier-jobs / Food orders, Pay and tips).

const SALT_ORDERS := 151
const SALT_CARGO := 152
const SALT_RIVAL := 153
## Share of orders that become higher-tier cargo when the licence allows it.
static var HIGHER_TIER_SHARE: float:
	get:
		return Economy.num("orders", "higher_tier_share")
static var PER_HOUR: int:
	get:
		return Economy.whole("orders", "per_hour")
static var RADIUS: int:
	get:
		return Economy.whole("orders", "radius")
static var BASE: float:
	get:
		return Economy.num("pay", "base")
static var PER_METRE: float:
	get:
		return Economy.num("pay", "per_metre")
static var PER_FLOOR: float:
	get:
		return Economy.num("pay", "per_floor")
static var TIP: float:
	get:
		return Economy.num("pay", "tip")
static var COOLING_MINUTES: float:
	get:
		return Economy.num("pay", "cooling_minutes")

var population: Population


func _init(p_population: Population) -> void:
	population = p_population


func offers(patron: WorkplaceInfo, day: int, hour: int, max_tier: int = 1) -> Array[DeliveryJob]:
	var result: Array[DeliveryJob] = []
	var layout := population.layout
	var seed_value := population.world_seed()
	var rng := CellRandom.new(DetHash.hash4(seed_value, SALT_ORDERS, patron.id.district.x * 7919 + patron.id.district.z,
			patron.id.district.y, patron.id.local, day * 24 + hour))
	var tries := 0
	while result.size() < PER_HOUR and tries < 200:
		tries += 1
		var cell := patron.cell + Vector3i(rng.range_int(-RADIUS, RADIUS), rng.range_int(-1, 1), rng.range_int(-RADIUS, RADIUS))
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		var flats := population.flats_of(block)
		if flats.is_empty():
			continue
		var flat: Vector2i = flats[rng.next_int(flats.size())]
		var adults: Array[PersonInfo] = []
		for p in population.residents(cell, flat.x, flat.y):
			if p.age >= 18:
				adults.append(p)
		if adults.is_empty():
			continue
		var customer := adults[rng.next_int(adults.size())]
		var job := DeliveryJob.new()
		job.id = "%s/%d/%d/%d" % [patron.key(), day, hour, result.size()]
		job.pickup = patron.id
		job.patron_name = patron.name
		job.dropoff_cell = cell
		job.dropoff_floor = flat.x
		job.dropoff_unit = flat.y
		job.customer = customer.id
		job.customer_name = customer.full_name()
		job.cargo = _cargo(patron, rng)
		job.distance = (Vector3(cell - patron.cell) * layout.config.cell_size).length()
		job.floors = absi(roundi((cell.y - patron.cell.y) * layout.config.cell_size.y / 4.0) + flat.x - patron.floor_index)
		job.base_pay = roundi(BASE + PER_METRE * job.distance + PER_FLOOR * job.floors)
		if max_tier >= 2:
			_upgrade_cargo(job, patron, day * 24 + hour, result.size(), max_tier)
		result.append(job)
	return result


## Turns some orders into higher-tier cargo (spec courier-progression / Higher tiers with a better
## licence); its own hash, so the orders themselves stay the same for every licence.
func _upgrade_cargo(job: DeliveryJob, patron: WorkplaceInfo, hour_index: int, index: int, max_tier: int) -> void:
	var h := DetHash.hash4(population.world_seed(), SALT_CARGO, patron.id.district.x * 7919 + patron.id.district.z,
			patron.id.local, hour_index, index)
	if DetHash.u01(h) >= HIGHER_TIER_SHARE:
		return
	var t := 2 + (h >> 20) % (max_tier - 1)
	var kinds := CargoKind.kinds_of_tier(t)
	var kind := kinds[(h >> 8) % kinds.size()]
	var labels: Array = CargoKind.TABLE[kind]["labels"]
	job.cargo_kind = kind
	job.cargo = labels[(h >> 12) % labels.size()]
	job.base_pay = roundi(job.base_pay * CargoKind.pay(kind))


static func _cargo(patron: WorkplaceInfo, rng: CellRandom) -> String:
	match patron.trade:
		"noodle bar":
			return ["noodles", "a bowl of ramen", "dumplings and broth"][rng.next_int(3)]
		"grocer":
			return ["a crate of greens", "rice and eggs", "fruit from the deep farms"][rng.next_int(3)]
	return ["a hot meal", "a dinner box", "skewers and buns"][rng.next_int(3)]


## Pay when delivered at `minute`: the base plus a tip that falls to zero over 30 game minutes.
## Minute of the hour at which a rival courier takes an order from the counter, or -1 if none does
## (spec rival-couriers).
func rival_minute(patron: WorkplaceInfo, day: int, hour: int, index: int) -> int:
	var h := DetHash.hash4(population.world_seed(), SALT_RIVAL, patron.id.district.x * 7919 + patron.id.district.z,
			patron.id.local, day * 24 + hour, index)
	if DetHash.u01(h) >= Economy.num("orders", "rival_share"):
		return -1
	return 10 + (h >> 12) % 50


static func pay_for(job: DeliveryJob, minute: int, tip_factor: float = 1.0) -> int:
	var elapsed := float(minute - job.picked_minute)
	var heat := clampf(1.0 - elapsed / COOLING_MINUTES, 0.0, 1.0)
	return job.base_pay + roundi(job.base_pay * TIP * heat * tip_factor)


static func heat_of(job: DeliveryJob, minute: int) -> float:
	return clampf(1.0 - float(minute - job.picked_minute) / COOLING_MINUTES, 0.0, 1.0)
