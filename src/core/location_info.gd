class_name LocationInfo
extends RefCounted
## Formats the location read-out (spec free-flight / Location read-out).


static func describe(layout: CityLayout, cell: Vector3i, kind: int) -> String:
	var lines := PackedStringArray()
	lines.append("Cell %d, %d, %d" % [cell.x, cell.y, cell.z])
	var y_rel := cell.y - layout.config.roof_layer
	if y_rel > 0:
		lines.append("Altitude %d layers above the roof" % y_rel)
	else:
		lines.append("Depth %d layers (%d m)" % [-y_rel, -y_rel * int(layout.config.cell_size.y)])
	var district := layout.district_of(cell)
	lines.append("District %d, %d, %d" % [district.x, district.y, district.z])
	lines.append("Open air" if kind == BlockTypes.NONE else "Inside: %s" % BlockTypes.display_name(kind))
	return "\n".join(lines)


## Read-out while inside a pocket space (spec pocket-spaces / Read-out inside a pocket space).
static func describe_pocket(pocket: PocketSpaceInfo) -> String:
	var lines := PackedStringArray()
	lines.append("Pocket space: %s" % PocketSpaceInfo.kind_name(pocket.kind))
	lines.append("%d × %d × %d m" % [roundi(pocket.size.x), roundi(pocket.size.y), roundi(pocket.size.z)])
	lines.append("behind cell %d, %d, %d" % [pocket.cell.x, pocket.cell.y, pocket.cell.z])
	return "\n".join(lines)
