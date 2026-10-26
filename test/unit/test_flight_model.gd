extends GutTest
## Spec free-flight: Six-degree-of-freedom flight, Boost, Mouse look.

const FORWARD := Vector3(0, 0, -1)
const RIGHT := Vector3(1, 0, 0)
const UP := Vector3(0, 1, 0)

var model: FlightModel


func before_each() -> void:
	model = FlightModel.new()


func test_flying_forward() -> void:
	var moved := model.velocity(0.0, 0.0, FORWARD, false) * 1.0
	assert_almost_eq(moved, Vector3(0, 0, -40), Vector3.ONE * 0.01)


func test_flying_forward_follows_the_view() -> void:
	var moved := model.velocity(deg_to_rad(90.0), 0.0, FORWARD, false)
	assert_almost_eq(moved, Vector3(-40, 0, 0), Vector3.ONE * 0.01)


func test_flying_up_while_looking_down() -> void:
	var moved := model.velocity(0.3, deg_to_rad(-60.0), UP, false) * 0.5
	assert_almost_eq(moved, Vector3(0, 20, 0), Vector3.ONE * 0.01)


func test_strafing_ignores_pitch() -> void:
	var moved := model.velocity(0.0, deg_to_rad(-60.0), RIGHT, false)
	assert_almost_eq(moved, Vector3(40, 0, 0), Vector3.ONE * 0.01)


func test_diagonal_input_is_not_faster() -> void:
	var moved := model.velocity(0.7, 0.2, FORWARD + RIGHT, false)
	assert_almost_eq(moved.length(), 40.0, 0.01)


func test_no_input_no_motion() -> void:
	assert_eq(model.velocity(1.0, 0.5, Vector3.ZERO, true), Vector3.ZERO)


func test_boosted_flight() -> void:
	var moved := model.velocity(0.0, 0.0, FORWARD, true)
	assert_almost_eq(moved.length(), 240.0, 0.01)


func test_pitch_is_clamped() -> void:
	var degrees_per_pixel := rad_to_deg(model.mouse_sensitivity)
	var look := model.apply_mouse(0.0, 0.0, Vector2(0, -200.0 / degrees_per_pixel))
	assert_almost_eq(rad_to_deg(look.y), 89.0, 0.001)
	look = model.apply_mouse(0.0, 0.0, Vector2(0, 200.0 / degrees_per_pixel))
	assert_almost_eq(rad_to_deg(look.y), -89.0, 0.001)


func test_yaw_is_unlimited() -> void:
	var degrees_per_pixel := rad_to_deg(model.mouse_sensitivity)
	var look := model.apply_mouse(0.0, 0.0, Vector2(-720.0 / degrees_per_pixel, 0))
	assert_almost_eq(rad_to_deg(look.x), 720.0, 0.001)
