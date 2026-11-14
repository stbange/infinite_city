class_name CityNav
extends RefCounted
## Routes over block graphs joined by bridges (spec city-navigation / Routes over bridges).

const CACHE := 256
const NODE_BUDGET := 60000
## How far (in cells, beyond the start and goal) a search may wander.
const MAX_CELLS := 2

var population: Population
var layout: CityLayout
var _navs: Dictionary = {}   # Vector3i -> BlockNav (or null for open air)
var _mutex := Mutex.new()
## Nodes the last search expanded (for tests and budgets).
var last_expanded: int = 0
## Extra cost in metres for crossing a bridge, by "cell|axis" key (spec wayfinding / Gang-aware
## routes). Both directions of a bridge use the same key.
var bridge_penalties: Dictionary = {}


func _init(p_population: Population) -> void:
	population = p_population
	layout = p_population.layout


## The navigation graph of the block in a cell, or null for open air.
func block_nav(cell: Vector3i) -> BlockNav:
	_mutex.lock()
	var cached: bool = _navs.has(cell)
	var nav: BlockNav = _navs.get(cell)
	_mutex.unlock()
	if cached:
		return nav
	var block := layout.block_at(cell)
	nav = BlockNav.new(population.plan_of(block)) if block != null else null
	_mutex.lock()
	if _navs.size() >= CACHE:
		_navs.clear()
	_navs[cell] = nav
	_mutex.unlock()
	return nav


## Global node of a place, or Vector4i with w = -1.
func node_of(place: NavPlace) -> Vector4i:
	var nav := block_nav(place.cell)
	var id := nav.node_of(place) if nav != null else -1
	return Vector4i(place.cell.x, place.cell.y, place.cell.z, id)


## Position of a global node relative to the centre of `origin`.
func position_of(node: Vector4i, origin: Vector3i) -> Vector3:
	var cell := Vector3i(node.x, node.y, node.z)
	return Vector3(cell - origin) * layout.config.cell_size + block_nav(cell).position(node.w)


## Neighbours of a global node as [Vector4i, cost], including the bridge to the next block.
func neighbours(node: Vector4i) -> Array:
	var cell := Vector3i(node.x, node.y, node.z)
	var nav := block_nav(cell)
	var local: Array = []
	nav.neighbours(node.w, local)
	var result: Array = []
	for pair: Array in local:
		result.append([Vector4i(cell.x, cell.y, cell.z, pair[0]), pair[1]])
	var t := nav.template_of(node.w)
	var floor_index := nav.floor_of(node.w)
	for key: int in nav.face_nodes:
		if nav.face_nodes[key] != t:
			continue
		var axis := key / 2
		var sign := 1 if key % 2 == 1 else -1
		if not nav.has_entrance(floor_index, axis, sign):
			continue
		var other_cell := cell + CityLayout.axis_unit(axis) * sign
		var bridge := layout.bridge_between(cell if sign > 0 else other_cell, axis)
		if bridge == null:
			continue
		var other := block_nav(other_cell)
		if other == null:
			continue
		var other_floor := other.plan.floor_at(bridge.start.y + layout.cell_center(bridge.cell_a).y - layout.cell_center(other_cell).y + 0.5)
		var other_t: int = other.face_nodes.get(BlockNav.face_key(axis, -sign), -1)
		if other_t < 0 or not other.has_entrance(other_floor, axis, -sign):
			continue
		var other_node := Vector4i(other_cell.x, other_cell.y, other_cell.z, other.node(other_floor, other_t))
		var cost := position_of(node, cell).distance_to(position_of(other_node, cell))
		cost += float(bridge_penalties.get(WorldOverlays.bridge_key(bridge), 0.0))
		result.append([other_node, cost])
	return result


## Shortest route between two places, or an empty route when none is found within the box and
## the node budget.
func route(from: NavPlace, to: NavPlace, max_cells: int = MAX_CELLS, budget: int = NODE_BUDGET) -> NavRoute:
	return route_between(node_of(from), node_of(to), max_cells, budget)


## The nav node nearest a point (relative to the centre of `cell`) on the floor it stands on, in
## the block of that cell; Vector4i with w = -1 when the cell has no block.
func nearest_node(cell: Vector3i, local: Vector3) -> Vector4i:
	var nav := block_nav(cell)
	if nav == null:
		return Vector4i(cell.x, cell.y, cell.z, -1)
	var floor_index := nav.plan.floor_at(local.y + 0.5)
	var best := -1
	var best_d := INF
	for t in nav.size:
		var d := nav.points[t].distance_squared_to(Vector2(local.x, local.z))
		if d < best_d:
			best_d = d
			best = t
	return Vector4i(cell.x, cell.y, cell.z, nav.node(floor_index, best))


## Shortest route between two global nodes (see route()).
func route_between(start: Vector4i, goal: Vector4i, max_cells: int = MAX_CELLS, budget: int = NODE_BUDGET) -> NavRoute:
	var result := NavRoute.new()
	result.start_cell = Vector3i(start.x, start.y, start.z)
	last_expanded = 0
	if start.w < 0 or goal.w < 0:
		return result
	var from_cell := Vector3i(start.x, start.y, start.z)
	var to_cell := Vector3i(goal.x, goal.y, goal.z)
	var lo := Vector3i(mini(from_cell.x, to_cell.x), mini(from_cell.y, to_cell.y), mini(from_cell.z, to_cell.z)) - Vector3i.ONE * max_cells
	var hi := Vector3i(maxi(from_cell.x, to_cell.x), maxi(from_cell.y, to_cell.y), maxi(from_cell.z, to_cell.z)) + Vector3i.ONE * max_cells
	var origin := from_cell
	var goal_pos := position_of(goal, origin)
	var dist := {start: 0.0}
	var came := {}
	var closed := {}
	var heap := _Heap.new()
	heap.push(position_of(start, origin).distance_to(goal_pos), start)
	while not heap.is_empty():
		var current: Vector4i = heap.pop()
		if closed.has(current):
			continue
		closed[current] = true
		last_expanded += 1
		if current == goal:
			break
		if last_expanded > budget:
			return result
		var base: float = dist[current]
		for pair: Array in neighbours(current):
			var next: Vector4i = pair[0]
			if closed.has(next) or next.x < lo.x or next.y < lo.y or next.z < lo.z or next.x > hi.x or next.y > hi.y or next.z > hi.z:
				continue
			var d: float = base + pair[1]
			if d < float(dist.get(next, INF)) - 0.000001:
				dist[next] = d
				came[next] = current
				heap.push(d + position_of(next, origin).distance_to(goal_pos), next)
	if not closed.has(goal):
		return result
	var node := goal
	result.nodes.append(node)
	while node != start:
		node = came[node]
		result.nodes.append(node)
	result.nodes.reverse()
	for n in result.nodes:
		result.points.append(position_of(n, origin))
	result.cost = dist[goal]
	result.length = _walking_length(result)
	return result


## Walking metres of a route: point distances, with stairs counted at their flight length.
func _walking_length(r: NavRoute) -> float:
	var total := 0.0
	for i in range(1, r.nodes.size()):
		var a := r.nodes[i - 1]
		var b := r.nodes[i]
		var same_cell := a.x == b.x and a.y == b.y and a.z == b.z
		var nav := block_nav(Vector3i(a.x, a.y, a.z))
		if same_cell and nav.floor_of(a.w) != nav.floor_of(b.w):
			total += BlockNav.STAIR_COST
		else:
			total += r.points[i - 1].distance_to(r.points[i])
	return total


## Binary min-heap of (priority, Vector4i).
class _Heap:
	var keys: PackedFloat64Array = PackedFloat64Array()
	var values: Array[Vector4i] = []

	func is_empty() -> bool:
		return values.is_empty()

	func push(key: float, value: Vector4i) -> void:
		keys.append(key)
		values.append(value)
		var i := values.size() - 1
		while i > 0:
			var parent := (i - 1) / 2
			if keys[parent] <= keys[i]:
				break
			_swap(i, parent)
			i = parent

	func pop() -> Vector4i:
		var top := values[0]
		var last := values.size() - 1
		_swap(0, last)
		keys.resize(last)
		values.resize(last)
		var i := 0
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var m := i
			if l < last and keys[l] < keys[m]:
				m = l
			if r < last and keys[r] < keys[m]:
				m = r
			if m == i:
				break
			_swap(i, m)
			i = m
		return top

	func _swap(a: int, b: int) -> void:
		var k := keys[a]
		keys[a] = keys[b]
		keys[b] = k
		var v := values[a]
		values[a] = values[b]
		values[b] = v
