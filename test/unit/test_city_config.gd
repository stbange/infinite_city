extends GutTest
## CityConfig: defaults and validation of tunables.


func test_defaults_are_valid() -> void:
	var config := CityConfig.new()
	assert_eq(config.validate(), PackedStringArray())


func test_default_values_match_spec() -> void:
	var config := CityConfig.new()
	assert_eq(config.cell_size, Vector3(64, 64, 64))
	assert_eq(config.roof_layer, 0)
	assert_eq(config.sky_layers, 4)
	assert_eq(config.district_size, 8)
	assert_eq(config.chunk_cells, 4)
	assert_almost_eq(config.base_density, 0.62, 1e-6)
	assert_almost_eq(config.shaft_chance, 0.25, 1e-6)
	assert_almost_eq(config.plaza_chance, 0.35, 1e-6)
	assert_almost_eq(config.bridge_chance, 0.3, 1e-6)
	assert_almost_eq(config.bridge_width, 6.0, 1e-6)
	assert_almost_eq(config.min_street_gap, 8.0, 1e-6)


func test_density_out_of_range_is_reported() -> void:
	var config := CityConfig.new()
	config.base_density = 1.5
	assert_eq(config.validate().size(), 1)


func test_fill_range_must_be_ordered() -> void:
	var config := CityConfig.new()
	config.block_fill_min = 0.9
	config.block_fill_max = 0.6
	assert_gt(config.validate().size(), 0)


func test_district_must_fit_canyons() -> void:
	var config := CityConfig.new()
	config.district_size = 3
	assert_gt(config.validate().size(), 0)


func test_bridge_must_fit_guaranteed_overlap() -> void:
	var config := CityConfig.new()
	config.bridge_width = 20.0
	assert_gt(config.validate().size(), 0)


func test_guaranteed_overlap_with_defaults() -> void:
	# Every block contains the cell centre +- 7.2 m on each axis with the defaults.
	var config := CityConfig.new()
	assert_almost_eq(config.guaranteed_core_half_extent(), Vector3(7.2, 7.2, 7.2), Vector3.ONE * 1e-4)
