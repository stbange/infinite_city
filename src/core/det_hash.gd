class_name DetHash
extends RefCounted
## Deterministic 32-bit hashing (MurmurHash3 x86_32 over 32-bit little-endian words).
##
## GDScript ints are 64-bit signed, so a plain 32 x 32-bit product may overflow. All
## multiplications go through mul32(), which keeps every intermediate below 2^49.
## Negative inputs are hashed as their two's-complement low 32 bits.
## The hashN helpers hash the words [seed_hi, salt, values...] with murmur seed = seed_lo,
## so 64-bit world seeds are fully used.

const MASK := 0xFFFFFFFF
const _C1 := 0xcc9e2d51
const _C2 := 0x1b873593
const _INV_2_32 := 1.0 / 4294967296.0


## (a * b) mod 2^32 for a, b in [0, 2^32).
static func mul32(a: int, b: int) -> int:
	return ((a * (b & 0xFFFF)) + (((a * (b >> 16)) & 0xFFFF) << 16)) & MASK


static func rotl32(x: int, r: int) -> int:
	return ((x << r) | (x >> (32 - r))) & MASK


static func _mix(h: int, k: int) -> int:
	k = mul32(k & MASK, _C1)
	k = ((k << 15) | (k >> 17)) & MASK
	k = mul32(k, _C2)
	h ^= k
	h = ((h << 13) | (h >> 19)) & MASK
	return ((h << 2) + h + 0xe6546b64) & MASK


static func _fmix(h: int, length_bytes: int) -> int:
	h ^= length_bytes
	h ^= h >> 16
	h = mul32(h, 0x85ebca6b)
	h ^= h >> 13
	h = mul32(h, 0xc2b2ae35)
	h ^= h >> 16
	return h


## Generic MurmurHash3 x86_32 of a sequence of 32-bit words.
static func murmur3_words(words: PackedInt64Array, seed_value: int) -> int:
	var h := seed_value & MASK
	for k in words:
		h = _mix(h, k)
	return _fmix(h, words.size() * 4)


static func hash1(seed_value: int, salt: int, a: int) -> int:
	var h := _mix(seed_value & MASK, (seed_value >> 32) & MASK)
	h = _mix(h, salt)
	h = _mix(h, a)
	return _fmix(h, 12)


static func hash2(seed_value: int, salt: int, a: int, b: int) -> int:
	var h := _mix(seed_value & MASK, (seed_value >> 32) & MASK)
	h = _mix(h, salt)
	h = _mix(h, a)
	h = _mix(h, b)
	return _fmix(h, 16)


static func hash3(seed_value: int, salt: int, a: int, b: int, c: int) -> int:
	var h := _mix(seed_value & MASK, (seed_value >> 32) & MASK)
	h = _mix(h, salt)
	h = _mix(h, a)
	h = _mix(h, b)
	h = _mix(h, c)
	return _fmix(h, 20)


static func hash4(seed_value: int, salt: int, a: int, b: int, c: int, d: int) -> int:
	var h := _mix(seed_value & MASK, (seed_value >> 32) & MASK)
	h = _mix(h, salt)
	h = _mix(h, a)
	h = _mix(h, b)
	h = _mix(h, c)
	h = _mix(h, d)
	return _fmix(h, 24)


## Hash of a cell: convenience wrapper around hash3.
static func hash_cell(seed_value: int, salt: int, cell: Vector3i) -> int:
	return hash3(seed_value, salt, cell.x, cell.y, cell.z)


## Maps a 32-bit hash to [0, 1).
static func u01(h: int) -> float:
	return float(h & MASK) * _INV_2_32
