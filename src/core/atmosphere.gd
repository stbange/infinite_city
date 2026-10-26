class_name Atmosphere
extends RefCounted
## Dark, foggy cyberpunk atmosphere (specs city-rendering / Depth atmosphere and
## city-lighting / Sunlight only on the uppermost layer, Dark ambience).
##
## Depths are in layers below the top of the roof layer (0 at the roof surface, 1 at the bottom
## of the roof layer, negative above the roof).

const FALLOFF_LAYERS := 80.0
const ABOVE_FOG := Color(0.17, 0.16, 0.27)
const BELOW_FOG := Color(0.15, 0.085, 0.22)
const DEEP_FOG := Color(0.065, 0.045, 0.11)
const ABOVE_DENSITY := 0.0025
const BELOW_DENSITY := 0.008
const DEEP_EXTRA_DENSITY := 0.002
const AMBIENT := 0.04
const SUN_ENERGY := 1.4
## Sunlight fades out over this many metres above and below the bottom of the roof layer.
const SUN_FADE_M := 16.0


## 1 at or above the roof, approaching 0 far below it.
static func openness(depth_layers: float) -> float:
	return exp(-maxf(depth_layers, 0.0) / FALLOFF_LAYERS)


## 0 above the roof surface, 1 from the bottom of the roof layer down.
static func _below(depth_layers: float) -> float:
	return smoothstep(0.0, 1.0, depth_layers)


static func fog_color(depth_layers: float) -> Color:
	var below := BELOW_FOG.lerp(DEEP_FOG, 1.0 - openness(depth_layers))
	return ABOVE_FOG.lerp(below, _below(depth_layers))


## Exponential fog density per metre.
static func fog_density(depth_layers: float) -> float:
	var below := BELOW_DENSITY + DEEP_EXTRA_DENSITY * (1.0 - openness(depth_layers))
	return lerpf(ABOVE_DENSITY, below, _below(depth_layers))


static func ambient_energy(_depth_layers: float = 0.0) -> float:
	return AMBIENT


## Energy of the light source (it is masked per surface by sun_visibility()).
static func light_energy(_depth_layers: float = 0.0) -> float:
	return SUN_ENERGY


## How much sunlight reaches a surface `metres` above the bottom of the roof layer.
## Mirrors the `light()` mask in the block and bridge shaders.
static func sun_visibility(metres_above_roof_bottom: float) -> float:
	return smoothstep(-SUN_FADE_M, SUN_FADE_M, metres_above_roof_bottom)
