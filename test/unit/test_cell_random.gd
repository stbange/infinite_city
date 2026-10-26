extends GutTest
## CellRandom: 32-bit PCG (RXS-M-XS) stream. Golden values from the Python reference.


func test_golden_sequence() -> void:
	var rng := CellRandom.new(12345)
	var expected := [4099845390, 430018922, 1600717359, 2315322805, 1683709501]
	for value: int in expected:
		assert_eq(rng.next_u32(), value)


func test_golden_sequence_seed_zero() -> void:
	var rng := CellRandom.new(0)
	assert_eq(rng.next_u32(), 129708002)
	assert_eq(rng.next_u32(), 582399676)
	assert_eq(rng.next_u32(), 1006035121)


func test_same_seed_same_sequence() -> void:
	var a := CellRandom.new(99)
	var b := CellRandom.new(99)
	for i in 100:
		assert_eq(a.next_u32(), b.next_u32())


func test_next_float_range() -> void:
	var rng := CellRandom.new(5)
	for i in 1000:
		var f := rng.next_float()
		assert_true(f >= 0.0 and f < 1.0)


func test_next_int_range_and_coverage() -> void:
	var rng := CellRandom.new(77)
	var seen := {}
	for i in 2000:
		var v := rng.next_int(8)
		assert_true(v >= 0 and v < 8)
		seen[v] = true
	assert_eq(seen.size(), 8)


func test_range_int_inclusive() -> void:
	var rng := CellRandom.new(3)
	var seen := {}
	for i in 500:
		var v := rng.range_int(2, 3)
		assert_true(v == 2 or v == 3)
		seen[v] = true
	assert_eq(seen.size(), 2)


func test_range_float_bounds() -> void:
	var rng := CellRandom.new(11)
	for i in 1000:
		var f := rng.range_float(-4.0, 6.0)
		assert_true(f >= -4.0 and f < 6.0)


func test_pick_weighted_follows_weights() -> void:
	var rng := CellRandom.new(2024)
	var counts := [0, 0, 0]
	for i in 6000:
		counts[rng.pick_weighted(PackedFloat32Array([1.0, 2.0, 3.0]))] += 1
	assert_between(counts[0], 850, 1150)
	assert_between(counts[1], 1800, 2200)
	assert_between(counts[2], 2750, 3250)
