extends GutTest
## Spec city-history: Reach histories, Territory, Local and deterministic.

var chronicle: CityChronicle


func before_each() -> void:
	chronicle = CityChronicle.new(CityConfig.new())


func _reaches(count: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var rng := CellRandom.new(11)
	while result.size() < count:
		result.append(Vector3i(rng.range_int(-40, 40), -rng.range_int(1, 30), rng.range_int(-40, 40)))
	return result


func _exists(key: String, year: int, reach: ReachHistory) -> bool:
	var faction := chronicle.faction(key)
	if faction == null:
		return false
	if faction.key.begins_with("R") and not reach.owns_key(key):
		return faction.founded <= year  # a neighbour's seeded gang
	return faction.exists_at(year)


func test_living_local_factions() -> void:
	for reach_coords in _reaches(40):
		var reach := chronicle.reach(reach_coords)
		assert_between(reach.factions.size(), 8, 24)
		var alive := {}
		for faction in reach.factions:
			if faction.exists_at(CityHistory.PRESENT_YEAR):
				alive[faction.type] = true
		for type: String in ["gang", "party", "guild"]:
			assert_true(alive.has(type), "no living %s in reach %s" % [type, reach_coords])


func test_consistent_events() -> void:
	for reach_coords in _reaches(40):
		var reach := chronicle.reach(reach_coords)
		var last := -1
		for event in reach.events:
			assert_gte(event.year, last)
			assert_between(event.year, 0, CityHistory.PRESENT_YEAR)
			last = event.year
			for key in event.actors:
				assert_true(_exists(key, event.year, reach), "%s at %d: %s" % [key, event.year, event.text])


func test_things_happen() -> void:
	for reach_coords in _reaches(40):
		var reach := chronicle.reach(reach_coords)
		assert_gte(reach.events.size(), 20)
		var takeovers := 0
		for event in reach.events:
			if event.kind == "takeover":
				takeovers += 1
		assert_gt(takeovers, 0, "no takeover in %s" % reach_coords)


func test_one_owner_per_district() -> void:
	for reach_coords in _reaches(10):
		var reach := chronicle.reach(reach_coords)
		for district in reach.districts():
			for year: int in [100, 300, 517]:
				var owner := reach.territory.owner_at(district, year)
				assert_false(owner.is_empty(), "district %s at %d" % [district, year])
				var faction := chronicle.faction(owner)
				assert_not_null(faction, owner)
				if faction != null:
					assert_true(faction.exists_at(year), "%s owns %s at %d but does not exist" % [owner, district, year])
		var any := reach.districts()[0]
		assert_eq(chronicle.owner_of_district(any), reach.territory.owner_at(any, CityHistory.PRESENT_YEAR))


func _signature(reach: ReachHistory) -> String:
	var parts := PackedStringArray()
	for faction in reach.factions:
		parts.append("%s %s %s %d %d" % [faction.key, faction.type, faction.name, faction.founded, faction.dissolved])
	for event in reach.events:
		parts.append("%d %s %s" % [event.year, event.kind, event.text])
	for district in reach.districts():
		parts.append("%s %s" % [district, reach.territory.owner_at(district, 517)])
	return "\n".join(parts)


func test_order_does_not_matter() -> void:
	var target := Vector3i(0, -2, 0)
	var alone := _signature(chronicle.reach(target))
	var other := CityChronicle.new(CityConfig.new())
	for step: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		other.reach(target + step)
	assert_eq(_signature(other.reach(target)), alone)


func test_border_feuds_stay_local() -> void:
	var found := 0
	for reach_coords in _reaches(40):
		var reach := chronicle.reach(reach_coords)
		for event in reach.events:
			if event.kind != "border_feud":
				continue
			found += 1
			var outsider := event.actors[1]
			assert_false(reach.owns_key(outsider))
			var neighbour := CityChronicle.reach_of_key(outsider)
			assert_eq(chronicle.first_seeded_gang(neighbour).key, outsider)
	assert_gt(found, 0, "no border feuds at all")


func test_reach_names() -> void:
	var names := {}
	for reach_coords in _reaches(40):
		var reach := chronicle.reach(reach_coords)
		assert_string_ends_with(reach.name, "Reach")
		names[reach.name] = true
	assert_gte(names.size(), 30)


func test_time_budget() -> void:
	var start := Time.get_ticks_usec()
	for i in 10:
		CityChronicle.new(CityConfig.new()).reach(Vector3i(i * 7, -3, -i * 5))
	var per_reach := (Time.get_ticks_usec() - start) / 10000.0
	assert_lt(per_reach, 150.0, "a Reach history should take well under 150 ms (took %.1f ms)" % per_reach)


## GUT keeps finished test scripts alive; release the big generators.
func after_all() -> void:
	chronicle = null
