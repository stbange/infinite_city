extends GutTest
## Spec on-foot-movement: Fall safety net.

const DT := 1.0 / 60.0


func _stand(guard: FallGuard, position: Vector3, seconds: float) -> bool:
	var reset := false
	for i in roundi(seconds / DT):
		reset = guard.update(true, position, DT) or reset
	return reset


func _fall(guard: FallGuard, from: Vector3, seconds: float) -> bool:
	var reset := false
	var position := from
	for i in roundi(seconds / DT):
		position.y -= 5.0 * DT
		if guard.update(false, position, DT):
			reset = true
			break
	return reset


func test_endless_fall() -> void:
	var guard := FallGuard.new()
	var roof := Vector3(10, 64, -3)
	assert_false(_stand(guard, roof, 1.0))
	assert_true(_fall(guard, roof, 4.1))
	assert_eq(guard.reset_point(), roof)


func test_short_falls_are_fine() -> void:
	var guard := FallGuard.new()
	_stand(guard, Vector3.ZERO, 1.0)
	assert_false(_fall(guard, Vector3.ZERO, 3.0))
	assert_false(_stand(guard, Vector3(0, -15, 0), 0.5))


func test_brief_touches_do_not_move_the_safe_point() -> void:
	var guard := FallGuard.new()
	var roof := Vector3(0, 64, 0)
	_stand(guard, roof, 1.0)
	_fall(guard, roof, 1.0)
	_stand(guard, Vector3(0, 40, 0), 0.1)
	assert_true(_fall(guard, Vector3(0, 40, 0), 4.1))
	assert_eq(guard.reset_point(), roof)


func test_no_reset_without_a_safe_point() -> void:
	var guard := FallGuard.new()
	assert_false(_fall(guard, Vector3.ZERO, 5.0))


func test_rebasing_shifts_the_safe_point() -> void:
	var guard := FallGuard.new()
	_stand(guard, Vector3(300, 10, 0), 1.0)
	guard.shift(Vector3(-256, 0, 0))
	assert_eq(guard.reset_point(), Vector3(44, 10, 0))
