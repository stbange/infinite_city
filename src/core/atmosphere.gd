class_name Atmosphere
extends RefCounted
## Depth-dependent atmosphere (spec city-rendering / Depth atmosphere).
## Brightness falls off exponentially with depth below the roof but never reaches zero.

const FALLOFF_LAYERS := 80.0
const TOP_FOG := Color(0.2, 0.25, 0.38)
const DEEP_FOG := Color(0.03, 0.036, 0.07)


## 1 at or above the roof, approaching 0 far below it.
static func openness(depth_layers: float) -> float:
	return exp(-maxf(depth_layers, 0.0) / FALLOFF_LAYERS)


static func fog_color(depth_layers: float) -> Color:
	return DEEP_FOG.lerp(TOP_FOG, openness(depth_layers))


## Energy of the light source as seen at this depth (the city above blocks part of it).
static func light_energy(depth_layers: float) -> float:
	return 0.25 + 0.95 * openness(depth_layers)


static func ambient_energy(depth_layers: float) -> float:
	return 0.14 + 0.22 * openness(depth_layers)
