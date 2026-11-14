class_name ArtStyle
extends RefCounted
## The city's look (spec art-style): a city in space, mostly greys and darkness, lit by warm
## sodium and cool white light, with colour kept for small, rare accents. Every system takes its
## colours from here, or passes its own through mute().

## Window light: most windows warm, some cool white, a few faintly tinted.
const WINDOW_WARM := Color(1.0, 0.76, 0.48)
const WINDOW_COOL := Color(0.78, 0.84, 0.92)
const WINDOW_ACCENT_SHARE := 0.05
## Share of windows lit (was 0.22): the city is darker.
const LIT_SHARE := 0.13
## Facades: dark steel grey; glass nearly black.
const FACADE := Color(0.075, 0.077, 0.083)
const GLASS := Color(0.015, 0.016, 0.018)
## Edge strips and bridge rails: dim grey-white instead of neon.
const STRIP := Color(0.55, 0.57, 0.6)
const STRIP_ENERGY := 0.5
## Lamps on bridges and in corridors.
const SODIUM := Color(1.0, 0.7, 0.42)
const COOL_WHITE := Color(0.8, 0.86, 0.95)
const LAMPS: Array[Color] = [SODIUM, SODIUM, COOL_WHITE]
const CORRIDOR_LIGHTS: Array[Color] = [Color(0.95, 0.88, 0.76), Color(0.8, 0.85, 0.92), Color(1.0, 0.78, 0.55)]
## Fog: blue-grey, dark below the fogline.
const FOG_ABOVE := Color(0.16, 0.165, 0.18)
const FOG_BELOW := Color(0.115, 0.12, 0.135)
const FOG_DEEP := Color(0.055, 0.058, 0.066)
const SUN_HAZE := Color(0.27, 0.26, 0.245)
## How much saturation signs, faction colours and furniture keep (0 grey … 1 unchanged).
const ACCENT_SATURATION := 0.35
## Figures: activity colours as muted cloth tones.
const FIGURE_SATURATION := 0.3
## Global grade applied by the environment.
const GRADE_SATURATION := 0.6
const GRADE_CONTRAST := 1.12
const GRADE_BRIGHTNESS := 0.95


## A colour with most of its saturation taken out (keeping `keep` of it) and a little of its
## brightness; the hue stays.
static func mute(color: Color, keep: float = ACCENT_SATURATION) -> Color:
	if keep >= 1.0:
		return color
	return Color.from_hsv(color.h, color.s * keep, color.v * (0.85 + 0.15 * keep), color.a)


static func saturation(color: Color) -> float:
	return color.s
