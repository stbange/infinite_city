extends GutTest
## Spec event-log: Event log and overlays.

var layout: CityLayout
var population: Population
var chronicle: CityChronicle
var cells: Array[Vector3i] = []


func before_all() -> void:
	layout = SharedCity.layout()
	population = SharedCity.population()
	chronicle = SharedCity.chronicle()
	var spawn := SpawnFinder.find_on_foot(layout)
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			cells.append(spawn.cell + Vector3i(dx, 0, dz))


func after_all() -> void:
	population = null
	layout = null
	chronicle = null


func _housing_flat() -> Array:
	for cell in cells:
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		for flat in population.flats_of(block):
			if not population.residents(cell, flat.x, flat.y).is_empty():
				return [cell, flat]
	return []


func _vacant_flat() -> Array:
	for cell in cells:
		var block := layout.block_at(cell)
		if block == null or block.kind != BlockTypes.Kind.HOUSING:
			continue
		for flat in population.flats_of(block):
			if population.household(cell, flat.x, flat.y).is_vacant():
				return [cell, flat]
	return []


func _sample_log() -> EventLog:
	var log := EventLog.new()
	var bridges := layout.bridges_of(cells[12])
	var some_bridge: BridgeInfo = bridges[0] if not bridges.is_empty() else null
	for cell in cells:
		if some_bridge == null and not layout.bridges_of(cell).is_empty():
			some_bridge = layout.bridges_of(cell)[0]
	log.append("bridge_taken", 100, {"bridge": WorldOverlays.bridge_key(some_bridge), "gang": "R0,-1,0#3", "from": ""})
	log.append("price", 200, {"district": WorldOverlays.district_key(layout.district_of(cells[0])), "factor": 1.3})
	var home := _housing_flat()
	var people := population.residents(home[0], home[1].x, home[1].y)
	log.append("death", 300, {"person": people[0].id.key()})
	return log


func test_replay() -> void:
	var log := _sample_log()
	var first := WorldOverlays.new()
	first.rebuild(log)
	var turf_a := TurfMap.new(chronicle, layout)
	turf_a.overlays = first
	var copy := EventLog.new()
	copy.from_dict(JSON.parse_string(JSON.stringify(log.to_dict())))
	var second := WorldOverlays.new()
	second.rebuild(copy)
	var turf_b := TurfMap.new(CityChronicle.new(CityConfig.new()), CityLayout.new(CityConfig.new()))
	turf_b.overlays = second
	var other_population := Population.new(CityLayout.new(CityConfig.new()), null)
	assert_eq(first.state_hash(population, turf_a, cells), second.state_hash(other_population, turf_b, cells))
	var empty := WorldOverlays.new()
	var turf_c := TurfMap.new(chronicle, layout)
	turf_c.overlays = empty
	assert_ne(first.state_hash(population, turf_a, cells), empty.state_hash(population, turf_c, cells))


func test_a_move_in_both_directions() -> void:
	var home := _housing_flat()
	var target := _vacant_flat()
	assert_false(target.is_empty())
	var mover := population.residents(home[0], home[1].x, home[1].y)[0]
	var log := EventLog.new()
	log.append("moved", 10, {"person": mover.id.key(), "to": [target[0].x, target[0].y, target[0].z, target[1].x, target[1].y]})
	var overlays := WorldOverlays.new()
	overlays.rebuild(log)
	var old_keys: Array[String] = []
	for p in overlays.residents(population, home[0], home[1].x, home[1].y):
		old_keys.append(p.id.key())
	var new_keys: Array[String] = []
	for p in overlays.residents(population, target[0], target[1].x, target[1].y):
		new_keys.append(p.id.key())
	assert_does_not_have(old_keys, mover.id.key())
	assert_has(new_keys, mover.id.key())


func test_claims_and_prices_from_events() -> void:
	var log := _sample_log()
	var overlays := WorldOverlays.new()
	overlays.rebuild(log)
	var turf := TurfMap.new(chronicle, layout)
	turf.overlays = overlays
	var key: String = log.events[0]["bridge"]
	var found := false
	for cell in cells:
		for bridge in layout.bridges_of(cell):
			if WorldOverlays.bridge_key(bridge) == key:
				assert_eq(turf.claim_of(bridge), "R0,-1,0#3")
				found = true
	assert_true(found)
	assert_almost_eq(overlays.price_factor(layout.district_of(cells[0])), 1.3, 0.0001)
	assert_true(overlays.is_dead(log.events[2]["person"]))
