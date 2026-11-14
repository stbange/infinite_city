class_name BlockNav
extends RefCounted
## Navigation graph of one block (spec city-navigation / Block navigation). One floor template in
## cell-local coordinates is shared by every floor: node id = floor × size + template index.

## Two 3 m flights rising 2 m each and the turn between them.
const STAIR_COST := 2.0 * 3.6056 + 1.2
## Blocks this tall have a lift in the stair core (spec transit / Lifts): waiting and riding cost.
const LIFT_MIN_FLOORS := 10
const LIFT_BASE := 12.0
const LIFT_PER_FLOOR := 1.0
## How far behind its door the node inside a unit lies.
const INSIDE := 1.0

var plan: InteriorPlan
var size: int = 0
## Template positions (x, z) of the nodes of one floor.
var points: PackedVector2Array = PackedVector2Array()
## Template edges: for each node the neighbour indices and costs.
var links: Array[PackedInt32Array] = []
var costs: Array[PackedFloat32Array] = []
var unit_nodes: PackedInt32Array = PackedInt32Array()
var door_nodes: PackedInt32Array = PackedInt32Array()
var landing: int = -1
## Template index of the corridor end at each face: key axis * 2 + (sign > 0 ? 1 : 0).
var face_nodes: Dictionary = {}


func _init(p_plan: InteriorPlan) -> void:
	plan = p_plan
	_build()


func floors() -> int:
	return plan.floors


func node(floor_index: int, template: int) -> int:
	return floor_index * size + template


func floor_of(id: int) -> int:
	return id / size


func template_of(id: int) -> int:
	return id % size


## Cell-local position of a node (y = the floor's walking surface).
func position(id: int) -> Vector3:
	var p := points[id % size]
	return Vector3(p.x, plan.floor_y(id / size), p.y)


## Node of a place in this block, or -1.
func node_of(place: NavPlace) -> int:
	if place.floor_index < 0 or place.floor_index >= plan.floors:
		return -1
	match place.where:
		NavPlace.Where.UNIT:
			return node(place.floor_index, unit_nodes[place.unit]) if place.unit >= 0 and place.unit < unit_nodes.size() else -1
		NavPlace.Where.DOOR:
			return node(place.floor_index, door_nodes[place.unit]) if place.unit >= 0 and place.unit < door_nodes.size() else -1
		_:
			var key := face_key(place.face_axis, place.face_sign)
			return node(place.floor_index, face_nodes[key]) if face_nodes.has(key) else -1


static func face_key(axis: int, sign: int) -> int:
	return axis * 2 + (1 if sign > 0 else 0)


## Neighbours within the block as pairs [node, cost]: the template edges plus the stairs.
func neighbours(id: int, into: Array) -> void:
	var t := id % size
	var base := id - t
	var l := links[t]
	var c := costs[t]
	for i in l.size():
		into.append([base + l[i], c[i]])
	if t == landing:
		var f := id / size
		if f > 0:
			into.append([id - size, STAIR_COST])
		if f < plan.floors - 1:
			into.append([id + size, STAIR_COST])
		if has_lift():
			for other in plan.floors:
				if absi(other - f) > 1:
					into.append([other * size + t, LIFT_BASE + LIFT_PER_FLOOR * absi(other - f)])


func has_lift() -> bool:
	return plan.floors >= LIFT_MIN_FLOORS


## Whether a bridge entrance (not a magic doorway) opens on this floor and face.
func has_entrance(floor_index: int, axis: int, sign: int) -> bool:
	return plan.has_entrance(floor_index, axis, sign)


# --- Building ------------------------------------------------------------------------------

func _add(p: Vector2) -> int:
	points.append(p)
	links.append(PackedInt32Array())
	costs.append(PackedFloat32Array())
	size += 1
	return size - 1


func _link(a: int, b: int, cost: float = -1.0) -> void:
	if a == b:
		return
	var d := points[a].distance_to(points[b]) if cost < 0.0 else cost
	links[a].append(b)
	costs[a].append(d)
	links[b].append(a)
	costs[b].append(d)


func _build() -> void:
	var inner := plan.inner
	# Points along each corridor's centre line: Array of [along, node].
	var along: Array[Array] = []
	var along_x: Array[bool] = []
	for corridor in plan.corridors:
		along.append([])
		along_x.append(corridor.size.x > corridor.size.y)
	unit_nodes.resize(plan.units.size())
	door_nodes.resize(plan.units.size())
	# Crossings: every corridor along x with every corridor along z.
	for i in plan.corridors.size():
		if not along_x[i]:
			continue
		for j in plan.corridors.size():
			if along_x[j]:
				continue
			var a := plan.corridors[i]
			var b := plan.corridors[j]
			var cross := Vector2(b.get_center().x, a.get_center().y)
			if cross.x >= a.position.x and cross.x <= a.end.x and cross.y >= b.position.y and cross.y <= b.end.y:
				var n := _add(cross)
				along[i].append([cross.x, n])
				along[j].append([cross.y, n])
	# Unit doors on the corridor they face.
	for unit in plan.units:
		var front := unit.front_z()
		var placed := false
		for i in plan.corridors.size():
			var c := plan.corridors[i]
			if not along_x[i] or unit.door_x < c.position.x or unit.door_x > c.end.x:
				continue
			var edge := c.position.y if unit.front_sign > 0 else c.end.y
			if absf(edge - front) > 0.05:
				continue
			var d := _add(Vector2(unit.door_x, c.get_center().y))
			along[i].append([unit.door_x, d])
			door_nodes[unit.index] = d
			var u := _add(Vector2(unit.door_x, front - unit.front_sign * INSIDE))
			unit_nodes[unit.index] = u
			_link(d, u)
			if unit.is_core:
				var lz := plan.core.position.y + InteriorLayout.LANDING * 0.5
				landing = _add(Vector2(plan.core.position.x + InteriorLayout.STAIR_WIDTH * 0.5, lz))
				_link(u, landing)
			placed = true
			break
		if not placed:
			push_warning("BlockNav: unit %d of %s faces no corridor" % [unit.index, plan.block.cell])
	# Corridor ends on the outer walls (entrances along x on the main corridor, along z on the
	# corridor through the centre).
	for i in plan.corridors.size():
		var c := plan.corridors[i]
		var centre := c.get_center()
		if along_x[i] and absf(centre.y) < 0.01:
			var w := _add(Vector2(inner.position.x, centre.y))
			var e := _add(Vector2(inner.end.x, centre.y))
			along[i].append([inner.position.x, w])
			along[i].append([inner.end.x, e])
			face_nodes[face_key(Vector3.AXIS_X, -1)] = w
			face_nodes[face_key(Vector3.AXIS_X, 1)] = e
		elif not along_x[i] and absf(centre.x) < 0.01:
			var s := _add(Vector2(centre.x, inner.position.y))
			var n := _add(Vector2(centre.x, inner.end.y))
			along[i].append([inner.position.y, s])
			along[i].append([inner.end.y, n])
			face_nodes[face_key(Vector3.AXIS_Z, -1)] = s
			face_nodes[face_key(Vector3.AXIS_Z, 1)] = n
	# Consecutive points along each corridor.
	for list in along:
		list.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
		for k in range(1, list.size()):
			_link(list[k - 1][1], list[k][1])
