class_name NavPlace
extends RefCounted
## A place people walk to (spec city-navigation): inside a unit, at a unit's door, or at the
## entrance where a bridge meets a block.

enum Where { UNIT, DOOR, ENTRANCE }

var cell: Vector3i
var floor_index: int
var unit: int = -1
var where: int = Where.UNIT
## Entrance face (axis X or Z and side) for ENTRANCE places.
var face_axis: int = 0
var face_sign: int = 0


static func inside(p_cell: Vector3i, p_floor: int, p_unit: int) -> NavPlace:
	var place := NavPlace.new()
	place.cell = p_cell
	place.floor_index = p_floor
	place.unit = p_unit
	place.where = Where.UNIT
	return place


static func door(p_cell: Vector3i, p_floor: int, p_unit: int) -> NavPlace:
	var place := inside(p_cell, p_floor, p_unit)
	place.where = Where.DOOR
	return place


static func entrance(p_cell: Vector3i, p_floor: int, axis: int, sign: int) -> NavPlace:
	var place := NavPlace.new()
	place.cell = p_cell
	place.floor_index = p_floor
	place.where = Where.ENTRANCE
	place.face_axis = axis
	place.face_sign = sign
	return place


func equals(other: NavPlace) -> bool:
	return other != null and cell == other.cell and floor_index == other.floor_index and unit == other.unit \
			and where == other.where and face_axis == other.face_axis and face_sign == other.face_sign


func _to_string() -> String:
	return "NavPlace(%s, fl %d, unit %d, %d)" % [cell, floor_index, unit, where]
