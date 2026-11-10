extends GutTest
## Specs gang-turf (Bridge claims, Tolls and heat) and encounters (Rolls depend on cargo and heat).

var layout: CityLayout
var chronicle: CityChronicle
var turf: TurfMap
var bridges: Array[BridgeInfo] = []


func before_all() -> void:
	var config := CityConfig.new()
	layout = CityLayout.new(config)
	chronicle = CityChronicle.new(config)
	turf = TurfMap.new(chronicle, layout)
	var spawn := SpawnFinder.find_on_foot(layout)
	var seen := {}
	for x in range(-12, 13, 2):
		for z in range(-12, 13, 2):
			for y in range(-3, 3):
				for bridge in layout.bridges_of(spawn.cell + Vector3i(x, y, z)):
					var key := "%s|%d" % [bridge.cell_a, bridge.axis]
					if not seen.has(key):
						seen[key] = true
						bridges.append(bridge)


func after_all() -> void:
	turf = null
	chronicle = null
	layout = null


func test_claims_follow_the_history() -> void:
	assert_gt(bridges.size(), 200)
	var claimed := 0
	for bridge in bridges:
		var district := layout.district_of(bridge.cell_a)
		var owner := chronicle.faction(chronicle.owner_of_district(district))
		var claim := turf.claim_of(bridge)
		if owner != null and owner.type == "gang":
			assert_eq(claim, owner.key)
		if claim.is_empty():
			continue
		claimed += 1
		var gang := turf.gang(claim)
		assert_eq(gang.type, "gang")
		assert_true(gang.exists_at(CityHistory.PRESENT_YEAR))
		assert_eq(CityChronicle.reach_of_key(claim), CityChronicle.reach_of(district))
	assert_gt(claimed, 5)
	assert_lt(claimed, bridges.size())


func test_deterministic_claims() -> void:
	var config := CityConfig.new()
	var other := TurfMap.new(CityChronicle.new(config), CityLayout.new(config))
	for i in range(0, bridges.size(), 7):
		assert_eq(other.claim_of(bridges[i]), turf.claim_of(bridges[i]))


func test_toll_grows_with_heat_and_cargo() -> void:
	assert_gt(EncounterRules.toll(2, 0.0), EncounterRules.toll(1, 0.0))
	assert_gt(EncounterRules.toll(1, 0.8), EncounterRules.toll(1, 0.0))


func test_heat_cools_down() -> void:
	var heat := Heat.new()
	heat.add("R0,0,0#1", 1.0, 1000)
	assert_almost_eq(heat.value_at("R0,0,0#1", 1000), 1.0, 0.0001)
	assert_almost_eq(heat.value_at("R0,0,0#1", 1120), 0.5, 0.0001)
	assert_eq(heat.value_at("R9,9,9#1", 1120), 0.0)
	var copy := Heat.new()
	copy.from_dict(JSON.parse_string(JSON.stringify(heat.to_dict())))
	assert_almost_eq(copy.value_at("R0,0,0#1", 1240), 0.25, 0.0001)


func test_rolls_depend_on_cargo_and_heat() -> void:
	var seed_value := layout.config.world_seed
	var counts := {"pass": 0, "toll": 0, "shakedown": 0}
	var hot := 0
	for bridge in bridges:
		assert_eq(EncounterRules.roll(seed_value, bridge, 1234, 0, 1.0), "pass")
		var cold := EncounterRules.roll(seed_value, bridge, 1234, 1, 0.0)
		counts[cold] += 1
		if EncounterRules.roll(seed_value, bridge, 1234, 1, 1.0) != "pass":
			hot += 1
		assert_eq(EncounterRules.roll(seed_value, bridge, 1234, 1, 0.0), cold)
	assert_gt(counts["pass"], 0)
	assert_gt(counts["toll"], 0)
	assert_gt(counts["shakedown"], 0)
	assert_gt(hot, counts["toll"] + counts["shakedown"])
