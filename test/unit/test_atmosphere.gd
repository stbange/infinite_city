extends GutTest
## Specs city-rendering (Depth atmosphere), city-fog (Fog by height) and city-lighting (Sunlight
## only on the uppermost layer, Dark ambience).


func test_deeper_is_darker() -> void:
	var top := Atmosphere.fog_color(0.0).get_luminance()
	var mid := Atmosphere.fog_color(50.0).get_luminance()
	var deep := Atmosphere.fog_color(500.0).get_luminance()
	assert_gt(top, mid)
	assert_gt(mid, deep)
	assert_gt(deep, 0.0)


func test_above_the_roof_is_brightest() -> void:
	assert_gte(Atmosphere.fog_color(-3.0).get_luminance(), Atmosphere.fog_color(0.0).get_luminance())


func test_dense_fog_below_the_roof() -> void:
	for depth: float in [1.5, 5.0, 50.0, 10000.0]:
		assert_gte(Atmosphere.fog_density(depth), 0.018, "fog too thin at depth %s" % depth)


func test_heavier_deeper_down() -> void:
	assert_gt(Atmosphere.fog_density(500.0), Atmosphere.fog_density(1.5))


func test_light_haze_in_the_roof_layer() -> void:
	assert_lte(Atmosphere.local_density(0.0, 0.02), 0.004)
	assert_lte(Atmosphere.local_density(0.5, 0.02), 0.004)


func test_fog_sea() -> void:
	assert_almost_eq(Atmosphere.local_density(1.5, 0.02), 0.02, 1e-6)
	assert_almost_eq(Atmosphere.local_density(20.0, 0.02), 0.02, 1e-6)


func test_clearing_above_the_roof() -> void:
	assert_lt(Atmosphere.local_density(-3.0, 0.02), 0.05 * Atmosphere.local_density(0.0, 0.02))


func test_thinner_fog_above_the_roof() -> void:
	assert_lt(Atmosphere.fog_density(-3.0), 0.5 * Atmosphere.fog_density(1.0))


func test_fog_hides_the_streaming_edge_below_the_roof() -> void:
	assert_lt(exp(-Atmosphere.fog_density(1.0) * 760.0), 0.01)


func test_sunlit_roof_layer() -> void:
	var layer := 64.0
	assert_eq(Atmosphere.sun_visibility(layer), 1.0, "top of the roof layer")
	assert_eq(Atmosphere.sun_visibility(16.0), 1.0, "16 m above the bottom of the roof layer")
	assert_eq(Atmosphere.sun_visibility(layer * 4.0), 1.0, "3 layers above the roof")


func test_dark_below() -> void:
	assert_eq(Atmosphere.sun_visibility(-16.0), 0.0)
	assert_eq(Atmosphere.sun_visibility(-16.0 - 5.0 * 64.0), 0.0)
	assert_eq(Atmosphere.sun_visibility(-640000000.0), 0.0)


func test_fade_at_the_bottom_of_the_roof_layer() -> void:
	assert_almost_eq(Atmosphere.sun_visibility(0.0), 0.5, 1e-6)


func test_low_ambient_light() -> void:
	for depth: float in [-3.0, 0.0, 1.0, 50.0, 10000.0]:
		assert_lte(Atmosphere.ambient_energy(depth), 0.05)
		assert_gt(Atmosphere.ambient_energy(depth), 0.0)
