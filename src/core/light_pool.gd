class_name LightPool
extends RefCounted
## Chooses which light anchors get one of the few real light sources (spec city-lighting /
## Real light near the player). Already chosen anchors are kept unless a candidate is at least
## `hysteresis` metres closer than the farthest chosen one.


static func select(anchors: Array[LightAnchor], camera: Vector3, count: int, current: Array[int],
		hysteresis: float = 10.0) -> Array[LightAnchor]:
	var sorted := anchors.duplicate()
	sorted.sort_custom(func(a: LightAnchor, b: LightAnchor) -> bool:
		return a.position.distance_squared_to(camera) < b.position.distance_squared_to(camera))
	var chosen: Array[LightAnchor] = []
	var current_set := {}
	for id in current:
		current_set[id] = true
	for anchor: LightAnchor in sorted:
		if current_set.has(anchor.id) and chosen.size() < count:
			chosen.append(anchor)
	for anchor: LightAnchor in sorted:
		if current_set.has(anchor.id):
			continue
		var distance := anchor.position.distance_to(camera)
		if chosen.size() < count:
			chosen.append(anchor)
			continue
		var farthest_index := _farthest(chosen, camera)
		if distance + hysteresis <= chosen[farthest_index].position.distance_to(camera):
			chosen[farthest_index] = anchor
		else:
			break
	return chosen


static func _farthest(chosen: Array[LightAnchor], camera: Vector3) -> int:
	var index := 0
	var best := -1.0
	for i in chosen.size():
		var d := chosen[i].position.distance_squared_to(camera)
		if d > best:
			best = d
			index = i
	return index
