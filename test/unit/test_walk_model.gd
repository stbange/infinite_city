extends GutTest
## Spec on-foot-movement: Walking, Sprinting, Jumping and gravity.

const DT := 1.0 / 60.0

var model: WalkModel


func before_each() -> void:
	model = WalkModel.new()


func _run(seconds: float, input: Vector2, sprint: bool, on_floor: bool, yaw: float = 0.0,
		start := Vector3.ZERO) -> Vector3:
	var velocity := start
	for i in roundi(seconds / DT):
		velocity = model.step(velocity, yaw, input, sprint, false, on_floor, DT)
	return velocity


func test_eye_height() -> void:
	assert_almost_eq(WalkModel.EYE_HEIGHT, 1.65, 1e-6)


func test_walking_forward() -> void:
	var v := _run(0.2, Vector2(0, 1), false, true)
	assert_almost_eq(v, Vector3(0, 0, -4.5), Vector3.ONE * 0.01)


func test_walking_follows_the_yaw() -> void:
	var v := _run(0.2, Vector2(0, 1), false, true, deg_to_rad(90.0))
	assert_almost_eq(v, Vector3(-4.5, 0, 0), Vector3.ONE * 0.01)


func test_diagonal_is_not_faster_and_stays_level() -> void:
	var v := _run(0.2, Vector2(1, 1), false, true, 0.4)
	assert_almost_eq(Vector2(v.x, v.z).length(), 4.5, 0.01)
	assert_eq(v.y, 0.0)


func test_sprinting() -> void:
	var v := _run(0.3, Vector2(0, 1), true, true)
	assert_almost_eq(Vector2(v.x, v.z).length(), 8.0, 0.01)


func test_stopping() -> void:
	var v := _run(0.2, Vector2.ZERO, false, true, 0.0, Vector3(0, 0, -4.5))
	assert_almost_eq(v.length(), 0.0, 0.01)


func test_jump_height() -> void:
	var velocity := model.step(Vector3.ZERO, 0.0, Vector2.ZERO, false, true, true, DT)
	assert_almost_eq(velocity.y, 4.6, 1e-5)
	var height := 0.0
	while velocity.y >= 0.0:
		height += velocity.y * DT
		velocity = model.step(velocity, 0.0, Vector2.ZERO, false, false, false, DT)
	assert_between(height, 1.0, 1.2)


func test_no_double_jump() -> void:
	var before := Vector3(0, 1.0, 0)
	var after := model.step(before, 0.0, Vector2.ZERO, false, true, false, DT)
	assert_lt(after.y, before.y)


func test_falling_accelerates() -> void:
	var v := _run(1.0, Vector2.ZERO, false, false)
	assert_almost_eq(v.y, -9.81, 0.01)


func test_air_control_is_weaker() -> void:
	var ground := _run(0.05, Vector2(0, 1), false, true)
	var air := _run(0.05, Vector2(0, 1), false, false)
	assert_lt(Vector2(air.x, air.z).length(), Vector2(ground.x, ground.z).length())
	assert_gt(Vector2(air.x, air.z).length(), 0.0)
