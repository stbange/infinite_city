class_name TransitNetwork
extends RefCounted
## Transit hubs (spec transit): each district's transit-hub block holds a platform, linked to the
## hubs of its neighbouring districts and, every fourth district row, to express hubs four rows up
## and down. Links are symmetric by construction.

const EXPRESS_ROWS := 4

var layout: CityLayout
var population: Population


func _init(p_population: Population) -> void:
	population = p_population
	layout = p_population.layout


## The platform of a district's hub: {cell, floor, unit, name}, or {} when the district has none.
func hub_of(district: Vector3i) -> Dictionary:
	var plan := layout.district_plan(district)
	for cell: Vector3i in plan:
		if plan[cell] != BlockTypes.Kind.TRANSIT_HUB:
			continue
		var block := layout.block_at(cell)
		if block == null:
			continue
		var interior := population.plan_of(block)
		for unit in interior.units:
			if not unit.is_core:
				var floor_index := 0
				return {"cell": cell, "floor": floor_index, "unit": unit.index, "district": district}
	return {}


static func is_express(district: Vector3i) -> bool:
	return posmod(district.y, EXPRESS_ROWS) == 0


## Districts a hub links to, in a fixed order: the four horizontal neighbours, the rows above and
## below, and the express hubs four rows away (from express rows only). Only districts that exist
## below the sky (row ≤ -1) are linked.
static func links(district: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var steps: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0)]
	if is_express(district):
		steps.append(Vector3i(0, EXPRESS_ROWS, 0))
		steps.append(Vector3i(0, -EXPRESS_ROWS, 0))
	for step in steps:
		var other := district + step
		if other.y <= -1:
			result.append(other)
	return result


static func fare(from: Vector3i, to: Vector3i) -> int:
	var express := absi(to.y - from.y) >= EXPRESS_ROWS
	return roundi(Economy.num("transit", "fare") * (Economy.num("transit", "express_factor") if express else 1.0))
