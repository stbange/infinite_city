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
	assert_almost_eq(config.base_density, 0.9, 1e-6)
	assert_almost_eq(config.roof_density, 0.96, 1e-6)
	assert_almost_eq(config.shaft_chance, 0.25, 1e-6)
	assert_almost_eq(config.plaza_chance, 0.35, 1e-6)
	assert_almost_eq(config.bridge_chance, 0.3, 1e-6)
	assert_almost_eq(config.bridge_width, 6.0, 1e-6)
	assert_almost_eq(config.street_setback_min, 2.0, 1e-6)
	assert_almost_eq(config.street_setback_max, 6.0, 1e-6)
	assert_almost_eq(config.lane_chance, 0.16, 1e-6)
	assert_almost_eq(config.lane_setback, 16.0, 1e-6)
	assert_almost_eq(config.lane_setback_jitter, 2.0, 1e-6)


func test_density_out_of_range_is_reported() -> void:
	var config := CityConfig.new()
	config.base_density = 1.5
	assert_eq(config.validate().size(), 1)


func test_street_setbacks_must_be_ordered() -> void:
	var config := CityConfig.new()
	config.street_setback_min = 6.0
	config.street_setback_max = 2.0
	assert_gt(config.validate().size(), 0)


func test_lane_setback_must_leave_a_core() -> void:
	var config := CityConfig.new()
	config.lane_setback = 31.0
	assert_gt(config.validate().size(), 0)


func test_district_must_fit_canyons() -> void:
	var config := CityConfig.new()
	config.district_size = 3
	assert_gt(config.validate().size(), 0)


func test_bridge_must_fit_guaranteed_overlap() -> void:
	var config := CityConfig.new()
	config.bridge_width = 40.0
	assert_gt(config.validate().size(), 0)


func test_guaranteed_overlap_with_defaults() -> void:
	# Every block contains the cell centre +- 14 m horizontally and +- 16 m vertically.
	var config := CityConfig.new()
	assert_almost_eq(config.guaranteed_core_half_extent(), Vector3(14, 16, 14), Vector3.ONE * 1e-4)
