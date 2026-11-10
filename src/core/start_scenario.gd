class_name StartScenario
extends RefCounted
## The courier's start (spec courier-jobs / Start scenario): the nearest active food business as
## patron and the nearest vacant flat as home.


static func find(population: Population, start: Vector3i) -> Dictionary:
	var layout := population.layout
	var cells: Array[Vector3i] = []
	for dx in range(-4, 5):
		for dy in range(-2, 1):
			for dz in range(-4, 5):
				cells.append(start + Vector3i(dx, dy, dz))
	cells.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		var da := Vector3(a - start).length_squared()
		var db := Vector3(b - start).length_squared()
		return da < db or (da == db and str(a) < str(b)))
	var result := {}
	for cell in cells:
		var d := cell - start
		if result.has("patron") or maxi(absi(d.x), absi(d.z)) > 3:
			continue
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.MARKET:
			continue
		var market := population.job_market(layout.district_of(cell))
		var plan := population.plan_of(block)
		for k in plan.floors:
			for unit in plan.units:
				if unit.is_core or result.has("patron"):
					continue
				var w := market.workplace_at(PersonId.of(layout, cell, k, unit.index, 0))
				if w != null and w.is_food and w.slots > 0:
					result["patron"] = w
	for cell in cells:
		if result.has("home_cell"):
			break
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		for flat in population.flats_of(block):
			if population.household(cell, flat.x, flat.y).is_vacant():
				result["home_cell"] = cell
				result["home_floor"] = flat.x
				result["home_unit"] = flat.y
				break
	if not result.has("patron") or not result.has("home_cell"):
		return {}
	return result
