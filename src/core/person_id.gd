class_name PersonId
extends RefCounted
## Identity of a person (or, with slot 0, of a unit): the district plus a local int packing the
## cell's position in the district (9 bits), floor (5 bits), unit (7 bits) and slot (3 bits).

var district: Vector3i
var local: int


func _init(p_district: Vector3i, p_local: int) -> void:
	district = p_district
	local = p_local


static func of(layout: CityLayout, cell: Vector3i, floor_index: int, unit: int, slot: int) -> PersonId:
	return PersonId.new(layout.district_of(cell), pack(layout.local_in_district(cell), floor_index, unit, slot))


static func pack(local_cell: Vector3i, floor_index: int, unit: int, slot: int) -> int:
	return (((local_cell.x * 8 + local_cell.y) * 8 + local_cell.z) << 15) | (floor_index << 10) | (unit << 3) | slot


func local_cell() -> Vector3i:
	var c := local >> 15
	return Vector3i(c / 64, (c / 8) % 8, c % 8)


func cell(layout: CityLayout) -> Vector3i:
	return layout.district_origin_cell(district) + local_cell()


func floor_index() -> int:
	return (local >> 10) & 31


func unit_index() -> int:
	return (local >> 3) & 127


func slot() -> int:
	return local & 7


func key() -> String:
	return "%d,%d,%d:%d" % [district.x, district.y, district.z, local]


static func from_key(text: String) -> PersonId:
	var parts := text.split(":")
	var d := parts[0].split(",")
	return PersonId.new(Vector3i(int(d[0]), int(d[1]), int(d[2])), int(parts[1]))


func equals(other: PersonId) -> bool:
	return other != null and other.district == district and other.local == local
