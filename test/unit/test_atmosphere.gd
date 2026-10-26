extends GutTest
## Spec city-rendering: Depth atmosphere.


func test_deeper_is_darker() -> void:
	var top := Atmosphere.fog_color(0.0).get_luminance()
	var mid := Atmosphere.fog_color(50.0).get_luminance()
	var deep := Atmosphere.fog_color(500.0).get_luminance()
	assert_gt(top, mid)
	assert_gt(mid, deep)
	assert_gt(deep, 0.0)


func test_above_the_roof_is_brightest() -> void:
	assert_gte(Atmosphere.fog_color(-3.0).get_luminance(), Atmosphere.fog_color(0.0).get_luminance())


func test_light_and_ambient_fade_with_depth() -> void:
	assert_gt(Atmosphere.light_energy(0.0), Atmosphere.light_energy(200.0))
	assert_gt(Atmosphere.ambient_energy(0.0), Atmosphere.ambient_energy(200.0))
	assert_gt(Atmosphere.ambient_energy(100000.0), 0.0)
