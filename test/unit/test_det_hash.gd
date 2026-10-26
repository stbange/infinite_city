extends GutTest
## DetHash: MurmurHash3 x86_32 over 32-bit words. Golden values come from an independent
## Python implementation cross-checked against the `mmh3` library and the published vectors.


func test_murmur3_published_vectors() -> void:
	assert_eq(DetHash.murmur3_words(PackedInt64Array(), 0), 0)
	assert_eq(DetHash.murmur3_words(PackedInt64Array(), 1), 0x514E28B7)
	assert_eq(DetHash.murmur3_words(PackedInt64Array([0]), 0), 0x2362F9DE)
	assert_eq(DetHash.murmur3_words(PackedInt64Array([0xFFFFFFFF]), 0), 0x76293B50)


func test_murmur3_reference_values() -> void:
	assert_eq(DetHash.murmur3_words(PackedInt64Array([1, 2, 3]), 42), 2814989487)
	assert_eq(DetHash.murmur3_words(PackedInt64Array([0xFFFFFFFF]), 0xFFFFFFFF), 2784895443)
	assert_eq(DetHash.murmur3_words(PackedInt64Array([0x87654321, 0x12345678]), 0x9747b28c), 2989991921)


func test_hash_with_negative_coordinates() -> void:
	assert_eq(DetHash.hash3(1337, 7, -1, -2, 3), 1938180954)


func test_hash_uses_high_bits_of_64_bit_seed() -> void:
	assert_eq(DetHash.hash2(0x100000005, 9, 10, 20), 4121000114)
	assert_ne(DetHash.hash2(0x100000005, 9, 10, 20), DetHash.hash2(5, 9, 10, 20))


func test_negative_seed() -> void:
	assert_eq(DetHash.hash1(-1, 0, 0), 2279185286)


func test_fixed_arity_helpers_match_generic_form() -> void:
	var seed_value := 987654321987
	var lo := seed_value & 0xFFFFFFFF
	var hi := (seed_value >> 32) & 0xFFFFFFFF
	assert_eq(DetHash.hash1(seed_value, 3, -5), DetHash.murmur3_words(PackedInt64Array([hi, 3, -5 & 0xFFFFFFFF]), lo))
	assert_eq(DetHash.hash2(seed_value, 3, -5, 6), DetHash.murmur3_words(PackedInt64Array([hi, 3, -5 & 0xFFFFFFFF, 6]), lo))
	assert_eq(DetHash.hash3(seed_value, 3, -5, 6, -7), DetHash.murmur3_words(PackedInt64Array([hi, 3, -5 & 0xFFFFFFFF, 6, -7 & 0xFFFFFFFF]), lo))
	assert_eq(DetHash.hash4(seed_value, 3, -5, 6, -7, 8), DetHash.murmur3_words(PackedInt64Array([hi, 3, -5 & 0xFFFFFFFF, 6, -7 & 0xFFFFFFFF, 8]), lo))


func test_results_are_unsigned_32_bit() -> void:
	for i in range(-200, 200):
		var h := DetHash.hash3(42, 1, i, i * 31, -i * 17)
		assert_true(h >= 0 and h <= 0xFFFFFFFF, "hash out of range: %d" % h)


func test_salt_changes_result() -> void:
	assert_ne(DetHash.hash3(42, 1, 5, 5, 5), DetHash.hash3(42, 2, 5, 5, 5))


func test_u01_range() -> void:
	assert_eq(DetHash.u01(0), 0.0)
	assert_lt(DetHash.u01(0xFFFFFFFF), 1.0)
	assert_almost_eq(DetHash.u01(0x80000000), 0.5, 1e-9)


func test_u01_is_roughly_uniform() -> void:
	var buckets := PackedInt32Array()
	buckets.resize(10)
	for i in 10000:
		var u := DetHash.u01(DetHash.hash3(7, 0, i, -i, i * 3))
		buckets[int(u * 10.0)] += 1
	for count in buckets:
		assert_between(count, 900, 1100)
