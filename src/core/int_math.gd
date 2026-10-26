class_name IntMath
extends RefCounted
## Integer helpers with floored semantics.
## GDScript's `/` and `%` truncate toward zero, which is wrong for negative grid coordinates:
## cell -1 must belong to district -1, not district 0.


## Largest integer q with q * b <= a. `b` must be positive.
static func floor_div(a: int, b: int) -> int:
	return (a - posmod(a, b)) / b


## a - floor_div(a, b) * b; always in [0, b). `b` must be positive.
static func floor_mod(a: int, b: int) -> int:
	return posmod(a, b)


static func floor_div_v3i(v: Vector3i, b: int) -> Vector3i:
	return Vector3i(floor_div(v.x, b), floor_div(v.y, b), floor_div(v.z, b))


static func floor_mod_v3i(v: Vector3i, b: int) -> Vector3i:
	return Vector3i(posmod(v.x, b), posmod(v.y, b), posmod(v.z, b))
