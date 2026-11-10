class_name InfluenceField
extends RefCounted
## Strength of a city-wide power at a district (spec city-history / Influence fields): smooth
## value noise on an 8-district lattice plus a depth preference by the power's kind.

const SALT_INFLUENCE := 113
const LATTICE := 8


## `depth` is in district layers below the roof's district (0 at the roof).
static func strength(world_seed: int, power_index: int, type: String, good: String, district: Vector3i,
		depth: float) -> float:
	var n := _noise(world_seed, power_index, district)
	return clampf(0.1 + 0.5 * n + 0.4 * depth_preference(type, good, maxf(depth, 0.0)), 0.0, 1.0)


static func depth_preference(type: String, good: String, depth: float) -> float:
	if type == "authority":
		return exp(-depth / 40.0)
	match good:
		"food", "water":
			return 1.0 - exp(-depth / 30.0)
		"power", "transit":
			return exp(-pow((depth - 30.0) / 40.0, 2.0))
	return 0.5


static func _noise(world_seed: int, power_index: int, district: Vector3i) -> float:
	var base := IntMath.floor_div_v3i(district, LATTICE)
	var f := Vector3(district - base * LATTICE) / float(LATTICE)
	var u := f * f * (Vector3.ONE * 3.0 - f * 2.0)
	var values: Array[float] = []
	for dz in 2:
		for dy in 2:
			for dx in 2:
				var c := base + Vector3i(dx, dy, dz)
				values.append(DetHash.u01(DetHash.hash4(world_seed, SALT_INFLUENCE, c.x, c.y, c.z, power_index)))
	var x00 := lerpf(values[0], values[1], u.x)
	var x10 := lerpf(values[2], values[3], u.x)
	var x01 := lerpf(values[4], values[5], u.x)
	var x11 := lerpf(values[6], values[7], u.x)
	return lerpf(lerpf(x00, x10, u.y), lerpf(x01, x11, u.y), u.z)
