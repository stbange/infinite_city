class_name PlaceNames
extends RefCounted
## Names of places (spec addresses / Place names): districts unique within their Reach, blocks
## named after their district and number, layers relative to the roof.

const SALT_DISTRICT_NAMES := 150

var layout: CityLayout
var _words: Array = []
var _orders: Dictionary = {}   # Reach -> Array of word indices (a permutation)


func _init(p_layout: CityLayout) -> void:
	layout = p_layout
	_words = DataTables.load_table("factions").data["reach_words"]


func reach_name(reach: Vector3i) -> String:
	return ReachHistory.name_of(layout.config, reach)


func district_name(district: Vector3i) -> String:
	var reach := CityChronicle.reach_of(district)
	var local := district - reach * CityChronicle.REACH_DISTRICTS
	var index := (local.x * 4 + local.y) * 4 + local.z
	return _words[_order(reach)[index]]


func block_number(cell: Vector3i) -> int:
	var local := layout.local_in_district(cell)
	return local.x * 64 + local.y * 8 + local.z + 1


func block_name(cell: Vector3i) -> String:
	return "%s-%d" % [district_name(layout.district_of(cell)), block_number(cell)]


func layer_label(y: int) -> String:
	return "L%d" % (y - layout.config.roof_layer)


## The district of a Reach with a given name, or null.
func district_named(reach: Vector3i, name: String) -> Variant:
	var order := _order(reach)
	for index in 64:
		if _words[order[index]] == name:
			return reach * CityChronicle.REACH_DISTRICTS + Vector3i(index / 16, (index / 4) % 4, index % 4)
	return null


func _order(reach: Vector3i) -> Array:
	if _orders.has(reach):
		return _orders[reach]
	var order: Array = range(_words.size())
	var rng := CellRandom.new(DetHash.hash3(layout.config.world_seed, SALT_DISTRICT_NAMES, reach.x, reach.y, reach.z))
	for i in range(order.size() - 1, 0, -1):
		var j := rng.next_int(i + 1)
		var tmp: Variant = order[i]
		order[i] = order[j]
		order[j] = tmp
	if _orders.size() > 256:
		_orders.clear()
	_orders[reach] = order
	return order
