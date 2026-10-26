extends GutTest
## IntMath: floored division and modulo (GDScript `/` truncates toward zero).


func test_floor_div_positive() -> void:
	assert_eq(IntMath.floor_div(7, 2), 3)
	assert_eq(IntMath.floor_div(8, 4), 2)
	assert_eq(IntMath.floor_div(0, 8), 0)


func test_floor_div_negative_rounds_down() -> void:
	assert_eq(IntMath.floor_div(-1, 8), -1)
	assert_eq(IntMath.floor_div(-8, 8), -1)
	assert_eq(IntMath.floor_div(-9, 8), -2)
	assert_eq(IntMath.floor_div(-7, 2), -4)


func test_floor_mod_is_never_negative() -> void:
	assert_eq(IntMath.floor_mod(-1, 8), 7)
	assert_eq(IntMath.floor_mod(-8, 8), 0)
	assert_eq(IntMath.floor_mod(-9, 8), 7)
	assert_eq(IntMath.floor_mod(9, 8), 1)


func test_floor_div_and_mod_reconstruct_value() -> void:
	for a in range(-50, 50):
		for b: int in [1, 3, 4, 8]:
			assert_eq(IntMath.floor_div(a, b) * b + IntMath.floor_mod(a, b), a)


func test_floor_div_vector() -> void:
	assert_eq(IntMath.floor_div_v3i(Vector3i(-1, 4, -9), 4), Vector3i(-1, 1, -3))


func test_floor_mod_vector() -> void:
	assert_eq(IntMath.floor_mod_v3i(Vector3i(-1, 4, -9), 4), Vector3i(3, 0, 3))


func test_large_values() -> void:
	assert_eq(IntMath.floor_div(-2147483648, 8), -268435456)
	assert_eq(IntMath.floor_div(2147483647, 8), 268435455)
