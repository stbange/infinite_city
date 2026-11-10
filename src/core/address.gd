class_name Address
extends RefCounted
## Door addresses (spec addresses / Addresses): "L-19 · Juniper Reach · Copper-217 · Fl 12 · Unit 4".

const SEPARATOR := " · "


static func format(names: PlaceNames, cell: Vector3i, floor_index: int, unit: int) -> String:
	var reach := CityChronicle.reach_of(names.layout.district_of(cell))
	return SEPARATOR.join(PackedStringArray([names.layer_label(cell.y), names.reach_name(reach),
			names.block_name(cell), "Fl %d" % (floor_index + 1), "Unit %d" % (unit + 1)]))


## {layer, reach, district, number, floor, unit} or {} when the text is no address.
static func parse(text: String) -> Dictionary:
	var parts := text.split(SEPARATOR)
	if parts.size() != 5 or not parts[0].begins_with("L") or not parts[3].begins_with("Fl ") \
			or not parts[4].begins_with("Unit "):
		return {}
	var dash := parts[2].rfind("-")
	if dash < 0:
		return {}
	return {
		"layer": int(parts[0].substr(1)),
		"reach": parts[1],
		"district": parts[2].substr(0, dash),
		"number": int(parts[2].substr(dash + 1)),
		"floor": int(parts[3].substr(3)) - 1,
		"unit": int(parts[4].substr(5)) - 1,
	}


## {cell, floor, unit} of an address, searching the Reaches around `near_cell`; {} if not found.
static func resolve_near(text: String, names: PlaceNames, near_cell: Vector3i) -> Dictionary:
	var parsed := parse(text)
	if parsed.is_empty():
		return {}
	var layout := names.layout
	var y: int = parsed["layer"] + layout.config.roof_layer
	var number: int = parsed["number"] - 1
	var local := Vector3i(number / 64, (number / 8) % 8, number % 8)
	var centre := CityChronicle.reach_of(layout.district_of(Vector3i(near_cell.x, y, near_cell.z)))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var reach := centre + Vector3i(dx, 0, dz)
			if names.reach_name(reach) != parsed["reach"]:
				continue
			var district: Variant = names.district_named(reach, parsed["district"])
			if district == null:
				continue
			var cell: Vector3i = layout.district_origin_cell(district) + local
			if cell.y != y:
				continue
			return {"cell": cell, "floor": parsed["floor"], "unit": parsed["unit"]}
	return {}
