extends GutTest
## Spec city-navigation: Block navigation, Routes over bridges.

var layout: CityLayout
var population: Population
var nav: CityNav


func before_all() -> void:
	layout = SharedCity.layout()
	population = SharedCity.population()
	nav = CityNav.new(population)


func after_all() -> void:
	nav = null
	population = null
	layout = null


## Blocks with at least one bridge entrance, scanning cells near the spawn.
func _bridged_blocks(count: int) -> Array[BlockInfo]:
	var spawn := SpawnFinder.find_on_foot(layout)
	var found: Array[BlockInfo] = []
	var r := 0
	while found.size() < count and r < 12:
		for x in range(-r, r + 1):
			for z in range(-r, r + 1):
				if maxi(absi(x), absi(z)) != r:
					continue
				for y in range(-2, 3):
					var cell := spawn.cell + Vector3i(x, y, z)
					var block := layout.block_at(cell)
					if block != null and not population.plan_of(block).entrances.is_empty():
						found.append(block)
						if found.size() >= count:
							return found
		r += 1
	return found


func _reachable(cell: Vector3i, start: int) -> Dictionary:
	var block_nav := nav.block_nav(cell)
	var seen := {start: true}
	var stack: Array[int] = [start]
	while not stack.is_empty():
		var n: int = stack.pop_back()
		var next: Array = []
		block_nav.neighbours(n, next)
		for pair: Array in next:
			if not seen.has(pair[0]):
				seen[pair[0]] = true
				stack.append(pair[0])
	return seen


func test_every_unit_reachable_from_every_entrance() -> void:
	var blocks := _bridged_blocks(200)
	assert_eq(blocks.size(), 200)
	var units := 0
	for block in blocks:
		var block_nav := nav.block_nav(block.cell)
		var plan := block_nav.plan
		for entrance in plan.entrances:
			var start := block_nav.node_of(NavPlace.entrance(block.cell, entrance.floor_index, entrance.face_axis, entrance.face_sign))
			assert_gte(start, 0, "entrance node of %s" % block.cell)
			var seen := _reachable(block.cell, start)
			for f in plan.floors:
				for u in plan.units.size():
					units += 1
					if not seen.has(block_nav.node_of(NavPlace.inside(block.cell, f, u))):
						fail_test("unit %d floor %d of %s unreachable" % [u, f, block.cell])
						return
	assert_gt(units, 1000)


func test_stairs_join_the_floors() -> void:
	var block: BlockInfo = null
	for candidate in _bridged_blocks(40):
		if population.plan_of(candidate).floors >= 4:
			block = candidate
			break
	assert_not_null(block)
	var route := nav.route(NavPlace.inside(block.cell, 0, 0), NavPlace.inside(block.cell, 3, 0))
	assert_false(route.is_empty())
	var block_nav := nav.block_nav(block.cell)
	for f in 4:
		assert_true(route.passes(block.cell, block_nav.node(f, block_nav.landing)), "landing of floor %d" % f)
	assert_gt(route.length, 3.0 * BlockNav.STAIR_COST)


func test_shortest_route_on_a_known_plan() -> void:
	var block := _bridged_blocks(1)[0]
	var plan := population.plan_of(block)
	# Two units on the main corridor's north side (front_sign -1, front at CORRIDOR_HALF), east half.
	var row: Array[InteriorUnit] = []
	for unit in plan.units:
		if unit.front_sign < 0 and absf(unit.front_z() - InteriorLayout.CORRIDOR_HALF) < 0.01 and unit.door_x > 0.0:
			row.append(unit)
	assert_gte(row.size(), 2)
	var a := row[0]
	var b := row[row.size() - 1]
	var route := nav.route(NavPlace.inside(block.cell, 1, a.index), NavPlace.inside(block.cell, 1, b.index))
	var expected := 2.0 * (BlockNav.INSIDE + InteriorLayout.CORRIDOR_HALF) + absf(b.door_x - a.door_x)
	assert_almost_eq(route.length, expected, 0.01)
	assert_almost_eq(route.points[0], Vector3(a.door_x, plan.floor_y(1), InteriorLayout.CORRIDOR_HALF + BlockNav.INSIDE), Vector3.ONE * 0.01)


func test_route_across_a_bridge() -> void:
	var block := _bridged_blocks(1)[0]
	var bridge := layout.bridges_of(block.cell)[0]
	var other_cell := bridge.cell_b if bridge.cell_a == block.cell else bridge.cell_a
	var route := nav.route(NavPlace.inside(block.cell, 0, 0), NavPlace.inside(other_cell, 0, 0))
	assert_false(route.is_empty())
	var sign := 1 if bridge.cell_a == block.cell else -1
	var here := population.plan_of(block)
	var floor_here := here.floor_at(bridge.start.y + 0.5)
	var floor_there := population.plan_of(layout.block_at(other_cell)).floor_at(bridge.start.y + 0.5)
	assert_true(route.passes(block.cell, nav.node_of(NavPlace.entrance(block.cell, floor_here, bridge.axis, sign)).w))
	assert_true(route.passes(other_cell, nav.node_of(NavPlace.entrance(other_cell, floor_there, bridge.axis, -sign)).w))
	assert_gte(route.length, bridge.length())
	# The same route found again after visiting other blocks first.
	nav.route(NavPlace.inside(other_cell, 0, 0), NavPlace.inside(other_cell, 1, 0))
	var again := nav.route(NavPlace.inside(block.cell, 0, 0), NavPlace.inside(other_cell, 0, 0))
	assert_eq(again.nodes, route.nodes)


func test_bounded_search() -> void:
	var block := _bridged_blocks(1)[0]
	var far := block.cell + Vector3i(40, 0, 0)
	while layout.block_at(far) == null:
		far.x += 1
	var route := nav.route(NavPlace.inside(block.cell, 0, 0), NavPlace.inside(far, 0, 0), CityNav.MAX_CELLS, 5000)
	assert_true(route.is_empty())
	assert_lte(nav.last_expanded, 5001)


func test_nearest_node_and_walking_length() -> void:
	var block := _bridged_blocks(1)[0]
	var plan := population.plan_of(block)
	var unit := plan.units[0]
	var near_door := Vector3(unit.door_x + 0.2, plan.floor_y(1) + 0.02, unit.front_z() + unit.front_sign * 1.2)
	var node := nav.nearest_node(block.cell, near_door)
	assert_eq(node, nav.node_of(NavPlace.door(block.cell, 1, 0)))
	var route := nav.route(NavPlace.inside(block.cell, 0, 0), NavPlace.inside(block.cell, 2, 0))
	assert_almost_eq(route.length, route.cost, 0.01, "no penalties: length is the cost")


func test_gang_bridges_cost_more() -> void:
	var block := _bridged_blocks(1)[0]
	var bridge := layout.bridges_of(block.cell)[0]
	var other_cell := bridge.cell_b if bridge.cell_a == block.cell else bridge.cell_a
	var plain := nav.route(NavPlace.inside(block.cell, 0, 0), NavPlace.inside(other_cell, 0, 0))
	nav.bridge_penalties = {WorldOverlays.bridge_key(bridge): 300.0}
	var careful := nav.route(NavPlace.inside(block.cell, 0, 0), NavPlace.inside(other_cell, 0, 0))
	nav.bridge_penalties = {}
	assert_false(careful.is_empty())
	var sign := 1 if bridge.cell_a == block.cell else -1
	var floor_here := population.plan_of(block).floor_at(bridge.start.y + 0.5)
	var entrance := nav.node_of(NavPlace.entrance(block.cell, floor_here, bridge.axis, sign)).w
	var crosses := careful.passes(block.cell, entrance)
	if crosses:
		assert_almost_eq(careful.cost, plain.cost + 300.0, 0.01, "no other way: the penalty is paid")
	else:
		assert_lt(careful.cost, plain.cost + 300.0, "a detour avoids the gang's bridge")
		assert_gt(careful.length, plain.length)
