extends GutTest
## Spec art-style: A restrained palette, Shadows, Colour grade.


func _is_pale(c: Color) -> bool:
	return c.s <= 0.6 and c.v >= 0.75


func test_greys_and_whites() -> void:
	for c: Color in [ArtStyle.FOG_ABOVE, ArtStyle.FOG_BELOW, ArtStyle.FOG_DEEP, ArtStyle.STRIP, ArtStyle.FACADE, ArtStyle.GLASS, ArtStyle.SUN_HAZE]:
		assert_lt(c.s, 0.2, "nearly grey: %s" % c)
	for c: Color in ArtStyle.LAMPS + ArtStyle.CORRIDOR_LIGHTS + [ArtStyle.WINDOW_WARM, ArtStyle.WINDOW_COOL]:
		assert_true(_is_pale(c), "a pale warm or cool white: %s" % c)
	assert_eq(Atmosphere.BELOW_FOG, ArtStyle.FOG_BELOW)
	assert_eq(CityLighting.LAMP_COLORS, ArtStyle.LAMPS)
	assert_eq(InteriorLayout.CORRIDOR_COLORS, ArtStyle.CORRIDOR_LIGHTS)


func test_muted_accents() -> void:
	var pink := Color(1.0, 0.16, 0.62)
	var muted := ArtStyle.mute(pink)
	assert_lt(muted.s, pink.s * 0.5)
	assert_almost_eq(muted.h, pink.h, 0.02, "the hue stays")
	assert_eq(ArtStyle.mute(pink, 1.0), pink)
	var grey := ArtStyle.mute(pink, 0.0)
	assert_almost_eq(grey.s, 0.0, 0.001)
