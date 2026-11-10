class_name CourierBoard
extends RefCounted
## Food orders offered at a patron's counter (spec courier-jobs / Food orders, Pay and tips).

const SALT_ORDERS := 151
const PER_HOUR := 3
const RADIUS := 2
const BASE := 12.0
const PER_METRE := 0.15
const PER_FLOOR := 3.0
const TIP := 0.4
const COOLING_MINUTES := 30.0

var population: Population


func _init(p_population: Population) -> void:
	population = p_population


func offers(patron: WorkplaceInfo, day: int, hour: int) -> Array[DeliveryJob]:
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
		result.append(job)
	return result


static func _cargo(patron: WorkplaceInfo, rng: CellRandom) -> String:
	match patron.trade:
		"noodle bar":
			return ["noodles", "a bowl of ramen", "dumplings and broth"][rng.next_int(3)]
		"grocer":
			return ["a crate of greens", "rice and eggs", "fruit from the deep farms"][rng.next_int(3)]
	return ["a hot meal", "a dinner box", "skewers and buns"][rng.next_int(3)]


## Pay when delivered at `minute`: the base plus a tip that falls to zero over 30 game minutes.
static func pay_for(job: DeliveryJob, minute: int) -> int:
	var elapsed := float(minute - job.picked_minute)
	var heat := clampf(1.0 - elapsed / COOLING_MINUTES, 0.0, 1.0)
	return job.base_pay + roundi(job.base_pay * TIP * heat)


static func heat_of(job: DeliveryJob, minute: int) -> float:
	return clampf(1.0 - float(minute - job.picked_minute) / COOLING_MINUTES, 0.0, 1.0)
