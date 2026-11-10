class_name Territory
extends RefCounted
## Who owns each district over time (spec city-history / Territory): per district a list of
## [year, owner key] claims in chronological order.

var _claims: Dictionary = {}   # Vector3i -> Array of [int, String]


func claim(district: Vector3i, year: int, owner: String) -> void:
	if not _claims.has(district):
		_claims[district] = []
	(_claims[district] as Array).append([year, owner])


## Owner at a year; years before the first claim get the first owner.
func owner_at(district: Vector3i, year: int) -> String:
	var list: Array = _claims.get(district, [])
	if list.is_empty():
		return ""
	for i in range(list.size() - 1, -1, -1):
		if int(list[i][0]) <= year:
			return list[i][1]
	return list[0][1]


func districts() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for d: Vector3i in _claims:
		result.append(d)
	return result


func claims_of(district: Vector3i) -> Array:
	return _claims.get(district, [])
