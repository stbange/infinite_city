extends GutTest
## Spec city-layout: Upper boundary, Sparse sky layers, Dense roof,
## Unbounded below and sideways, Block density.

const R := 0
const S := 4

var layout: CityLayout


func before_each() -> void:
	layout = CityLayout.new(CityConfig.new())


func _solid_fraction(lay: CityLayout, origin: Vector3i, size_x: int, size_z: int) -> float:
	var solid := 0
	for x in size_x:
		for z in size_z:
			if lay.is_solid(origin + Vector3i(x, 0, z)):
				solid += 1
	return float(solid) / float(size_x * size_z)


func test_nothing_above_the_sky_layers() -> void:
	var rng := CellRandom.new(1)
	var solid := 0
	for i in 20000:
		var cell := Vector3i(rng.range_int(-1000000, 1000000), rng.range_int(R + S + 1, R + 1000),
				rng.range_int(-1000000, 1000000))
		if layout.is_solid(cell):
			solid += 1
	assert_eq(solid, 0)


func test_sky_layers_thin_out_upward() -> void:
	var previous := 2.0
	for k in range(1, S + 1):
		var fraction := _solid_fraction(layout, Vector3i(-32, R + k, -32), 64, 64)
		assert_gt(fraction, 0.0, "sky layer %d should hold some blocks" % k)
		assert_lte(fraction, 0.10, "sky layer %d too dense" % k)
		assert_lt(fraction, previous, "sky layer %d should be sparser than the one below" % k)
		previous = fraction


func test_roof_is_denser_than_layers_below() -> void:
	var roof := _solid_fraction(layout, Vector3i(-32, R, -32), 64, 64)
	var below := _solid_fraction(layout, Vector3i(-32, R - 10, -32), 64, 64)
	assert_gte(roof, 0.70)
	assert_gt(roof, below)


func test_far_regions_are_as_dense_as_near_ones() -> void:
	var near := _solid_fraction(layout, Vector3i(-32, R - 20, -32), 64, 64)
	var deep := _solid_fraction(layout, Vector3i(-32, -10000000, -32), 64, 64)
	var far_side := _solid_fraction(layout, Vector3i(100000000, R - 20, -100000000), 64, 64)
	assert_almost_eq(deep, near, 0.08)
	assert_almost_eq(far_side, near, 0.08)


func test_density_of_uncarved_cells() -> void:
	var rng := CellRandom.new(2)
	var sampled := 0
	var solid := 0
	while sampled < 10000:
		var cell := Vector3i(rng.range_int(-500, 500), rng.range_int(R - 50, R - 1), rng.range_int(-500, 500))
		if layout.is_carved(cell):
			continue
		sampled += 1
		if layout.is_solid(cell):
			solid += 1
	assert_between(float(solid) / sampled, 0.57, 0.67)


func test_moved_roof_moves_the_boundary() -> void:
	var config := CityConfig.new()
	config.roof_layer = 10
	var moved := CityLayout.new(config)
	assert_gte(_solid_fraction(moved, Vector3i(-32, 10, -32), 64, 64), 0.70)
	assert_eq(_solid_fraction(moved, Vector3i(-32, 10 + S + 1, -32), 64, 64), 0.0)
	assert_gt(_solid_fraction(moved, Vector3i(-32, 10 + S, -32), 64, 64), 0.0)
