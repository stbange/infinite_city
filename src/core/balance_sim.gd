class_name BalanceSim
extends RefCounted
## A scripted courier playing the delivery loop (spec economy-tables / Balance report): takes the
## counter's orders, walks the routes at walking pace, and records what a day of steady play earns.
## It stands in for numbers a playtest would measure, so the economy table can be tuned.

const WALK_SPEED := 4.5
## Metres added for finding the door, ringing and the hand-over.
const DOOR_OVERHEAD := 25.0
const FALLBACK_DETOUR := 1.6

var population: Population
var nav: CityNav
var board: CourierBoard


func _init(p_population: Population) -> void:
	population = p_population
	nav = CityNav.new(population)
	board = CourierBoard.new(population)


## Plays from `start` to `end` (absolute game minutes) at `speed` game minutes per real second.
## Returns {deliveries, earnings, tips, metres, minutes_per_delivery, real_minutes}.
func play(patron: WorkplaceInfo, start: int, end: int, speed: float = GameClock.DEFAULT_SPEED, max_tier: int = 1) -> Dictionary:
	var minute := float(start)
	var taken := {}
	var stats := {"deliveries": 0, "earnings": 0, "tips": 0, "metres": 0.0}
	var counter := NavPlace.door(patron.cell, patron.floor_index, patron.unit)
	while minute < end:
		var clock := GameClock.at(int(minute))
		var bag: Array[DeliveryJob] = []
		var offers := board.offers(patron, clock.day_number(), clock.hour(), max_tier)
		for i in offers.size():
			var job := offers[i]
			var rival := board.rival_minute(patron, clock.day_number(), clock.hour(), i)
			if rival >= 0 and clock.minute() >= rival:
				continue
			if not taken.has(job.id) and bag.size() < 3:
				bag.append(job)
				taken[job.id] = true
		if bag.is_empty():
			minute = (floorf(minute / 60.0) + 1.0) * 60.0
			continue
		var here := counter
		for job in bag:
			job.picked_minute = int(minute)
		for job in bag:
			var door := NavPlace.door(job.dropoff_cell, job.dropoff_floor, job.dropoff_unit)
			var metres := walk(here, door) + DOOR_OVERHEAD
			minute += metres / WALK_SPEED * speed
			stats["metres"] += metres
			var pay := CourierBoard.pay_for(job, int(minute))
			stats["deliveries"] += 1
			stats["earnings"] += pay
			stats["tips"] += pay - job.base_pay
			here = door
		var back := walk(here, counter)
		minute += back / WALK_SPEED * speed
		stats["metres"] += back
	stats["minutes_per_delivery"] = float(end - start) / maxf(1.0, stats["deliveries"])
	stats["real_minutes"] = float(end - start) / speed / 60.0
	return stats


## Walking metres between two places: the route, or the straight line with a detour factor when
## the route is too far to search.
func walk(from: NavPlace, to: NavPlace) -> float:
	var route := nav.route(from, to, CityNav.MAX_CELLS, 20000)
	if not route.is_empty():
		return route.length
	var a := Vector3(from.cell) * population.layout.config.cell_size
	var b := Vector3(to.cell) * population.layout.config.cell_size
	return a.distance_to(b) * FALLBACK_DETOUR
