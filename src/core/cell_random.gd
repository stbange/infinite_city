class_name CellRandom
extends RefCounted
## Small deterministic random stream: 32-bit PCG (RXS-M-XS variant).
## Seed it with a DetHash value; every draw is a pure function of the seed and draw index.

const MASK := 0xFFFFFFFF
const _INV_2_32 := 1.0 / 4294967296.0

var _state: int


func _init(seed_value: int) -> void:
	_state = seed_value & MASK


func next_u32() -> int:
	_state = (DetHash.mul32(_state, 747796405) + 2891336453) & MASK
	var s := _state
	var word := DetHash.mul32(((s >> ((s >> 28) + 4)) ^ s) & MASK, 277803737)
	return ((word >> 22) ^ word) & MASK


## Uniform float in [0, 1).
func next_float() -> float:
	return float(next_u32()) * _INV_2_32


## Uniform int in [0, n). `n` must be in [1, 2^31).
func next_int(n: int) -> int:
	return (next_u32() * n) >> 32


## Uniform int in [lo, hi] (inclusive).
func range_int(lo: int, hi: int) -> int:
	return lo + next_int(hi - lo + 1)


## Uniform float in [a, b).
func range_float(a: float, b: float) -> float:
	return a + (b - a) * next_float()


## Index drawn with probability proportional to its weight. Weights must sum to > 0.
func pick_weighted(weights: PackedFloat32Array) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var target := next_float() * total
	var acc := 0.0
	for i in weights.size():
		acc += weights[i]
		if target < acc:
			return i
	return weights.size() - 1
