class_name CourierStart
extends RefCounted
## Finds the courier's patron and home around a cell on a worker thread (spec courier-jobs / Start
## scenario), with its own layout and population, and hands the result back on the main thread.


static func submit(world: CityWorld, cell: Vector3i) -> void:
	var config := world.config
	world.background.submit(["start", cell], func() -> Variant:
		var population := Population.new(CityLayout.new(config), null)
		var found := StartScenario.find(population, cell)
		if found.is_empty():
			return {}
		var w: WorkplaceInfo = found["patron"]
		return {"patron": [w.cell, w.floor_index, w.unit], "home": [found["home_cell"], found["home_floor"], found["home_unit"]]})


## null while the search runs; then {} when nothing was found, else {patron: WorkplaceInfo, home}.
static func poll(world: CityWorld, cell: Vector3i) -> Variant:
	var key := ["start", cell]
	world.background.poll()
	if not world.background.is_ready(key):
		return null
	var found: Dictionary = world.background.result(key)
	if found.is_empty():
		return {}
	var p: Array = found["patron"]
	var market := world.population.job_market(world.layout.district_of(p[0]))
	var h: Array = found["home"]
	return {"patron": market.workplace_at(PersonId.of(world.layout, p[0], p[1], p[2], 0)),
		"home": {"cell": h[0], "floor": h[1], "unit": h[2]}}
