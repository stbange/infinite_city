extends GutTest
## Spec transit: Transit hubs, Lifts.

var population: Population
var network: TransitNetwork
var start_district: Vector3i


func before_all() -> void:
	population = SharedCity.population()
	network = TransitNetwork.new(population)
	start_district = population.layout.district_of(SpawnFinder.find_on_foot(population.layout).cell)


func test_every_district_has_a_hub() -> void:
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for dy: int in [0, -1, -4]:
				var district := start_district + Vector3i(dx, dy, dz)
				if district.y > -1:
					continue
				var hub := network.hub_of(district)
				assert_false(hub.is_empty(), str(district))
				assert_eq(population.layout.block_kind_at(hub["cell"]), BlockTypes.Kind.TRANSIT_HUB)
				assert_eq(population.layout.district_of(hub["cell"]), district)
				assert_false(population.plan_of(population.layout.block_at(hub["cell"])).units[hub["unit"]].is_core)


func test_links_are_symmetric() -> void:
	for dy in range(-1, -10, -1):
		var district := Vector3i(start_district.x, dy, start_district.z)
		for other in TransitNetwork.links(district):
			assert_has(TransitNetwork.links(other), district, "%s <-> %s" % [district, other])
	var express := Vector3i(0, -4, 0)
	assert_true(TransitNetwork.is_express(express))
	assert_has(TransitNetwork.links(express), Vector3i(0, -8, 0))
	assert_does_not_have(TransitNetwork.links(Vector3i(0, -3, 0)), Vector3i(0, -7, 0))
	assert_does_not_have(TransitNetwork.links(Vector3i(0, -1, 0)), Vector3i(0, 0, 0), "nothing in the sky")
	assert_gt(TransitNetwork.fare(express, Vector3i(0, -8, 0)), TransitNetwork.fare(express, Vector3i(1, -4, 0)))


func test_lifts_in_tall_blocks() -> void:
	var spawn := SpawnFinder.find_on_foot(population.layout)
	var nav := CityNav.new(population)
	var tall: BlockInfo = null
	for dx in range(-8, 9):
		for dz in range(-8, 9):
			var block := population.layout.block_at(spawn.cell + Vector3i(dx, -1, dz))
			if block != null and population.plan_of(block).floors >= BlockNav.LIFT_MIN_FLOORS + 2:
				tall = block
				break
		if tall != null:
			break
	assert_not_null(tall)
	var plan := population.plan_of(tall)
	var top := plan.floors - 1
	var route := nav.route(NavPlace.inside(tall.cell, 0, 0), NavPlace.inside(tall.cell, top, 0))
	assert_false(route.is_empty())
	assert_lt(route.cost, BlockNav.STAIR_COST * top, "the lift beats the stairs")
	assert_true(nav.block_nav(tall.cell).has_lift())
