extends GutTest
## Spec city-lighting: Real light near the player.


func _anchors(count: int) -> Array[LightAnchor]:
	var anchors: Array[LightAnchor] = []
	var rng := CellRandom.new(12)
	for i in count:
		var position := Vector3(rng.range_float(-60, 60), rng.range_float(-20, 20), rng.range_float(-60, 60))
		anchors.append(LightAnchor.new(1000 + i, position, Color.WHITE, 2.0, 15.0))
	return anchors


func _ids(chosen: Array[LightAnchor]) -> Array[int]:
	var ids: Array[int] = []
	for anchor in chosen:
		ids.append(anchor.id)
	ids.sort()
	return ids


func test_nearest_light_anchors_are_chosen() -> void:
	var anchors := _anchors(40)
	var chosen := LightPool.select(anchors, Vector3.ZERO, 12, [])
	assert_eq(chosen.size(), 12)
	var by_distance := anchors.duplicate()
	by_distance.sort_custom(func(a: LightAnchor, b: LightAnchor) -> bool:
		return a.position.length() < b.position.length())
	assert_eq(_ids(chosen), _ids(by_distance.slice(0, 12)))


func test_fewer_anchors_than_lights() -> void:
	assert_eq(LightPool.select(_anchors(5), Vector3.ZERO, 12, []).size(), 5)


func test_small_moves_keep_the_lights() -> void:
	var anchors := _anchors(40)
	var first := _ids(LightPool.select(anchors, Vector3.ZERO, 12, []))
	for direction: Vector3 in [Vector3(3, 0, 0), Vector3(0, 0, -3), Vector3(2, 2, 1).normalized() * 3.0]:
		var again := _ids(LightPool.select(anchors, direction, 12, first))
		assert_eq(again, first, "moving %s changed the lights" % direction)


func test_much_closer_anchors_take_over() -> void:
	var anchors: Array[LightAnchor] = []
	for i in 12:
		var angle := TAU * i / 12.0
		anchors.append(LightAnchor.new(i, Vector3(cos(angle), 0, sin(angle)) * (12.0 + i), Color.WHITE, 2.0, 15.0))
	var current := _ids(LightPool.select(anchors, Vector3.ZERO, 12, []))
	anchors.append(LightAnchor.new(99, Vector3(1, 0, 0), Color.WHITE, 2.0, 15.0))
	var chosen := _ids(LightPool.select(anchors, Vector3.ZERO, 12, current))
	assert_true(chosen.has(99), "the close anchor should be lit")
	assert_false(chosen.has(11), "the farthest anchor should be dropped")
	assert_eq(chosen.size(), 12)


func test_vanished_anchors_are_replaced() -> void:
	var anchors := _anchors(40)
	var first := _ids(LightPool.select(anchors, Vector3.ZERO, 12, []))
	var remaining: Array[LightAnchor] = []
	for anchor in anchors:
		if anchor.id != first[0]:
			remaining.append(anchor)
	var again := LightPool.select(remaining, Vector3.ZERO, 12, first)
	assert_eq(again.size(), 12)
	assert_false(_ids(again).has(first[0]))
