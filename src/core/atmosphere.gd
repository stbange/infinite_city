class_name Atmosphere
extends RefCounted
## Dark, foggy cyberpunk atmosphere (specs city-rendering / Depth atmosphere, city-fog and
## city-lighting / Sunlight only on the uppermost layer, Dark ambience).
##
## Depths are in layers below the top of the roof layer (0 at the roof surface, 1 at the bottom
## of the roof layer, negative above the roof).

const FALLOFF_LAYERS := 80.0
const ABOVE_FOG := Color(0.17, 0.16, 0.27)
const BELOW_FOG := Color(0.15, 0.085, 0.22)
const DEEP_FOG := Color(0.065, 0.045, 0.11)
const ABOVE_DENSITY := 0.0015
const BELOW_DENSITY := 0.02
const DEEP_EXTRA_DENSITY := 0.004
## Above the roof surface the fog thins by a factor e every CLEAR_LAYERS layers.
const CLEAR_LAYERS := 0.5
## The top of the heavy fog (the "fog sea") lies at the bottom of the roof layer, where sunlight
## fades out; the fog thickens over FOG_SEA_BAND layers above and below it.
const FOG_SEA_DEPTH := 1.0
const FOG_SEA_BAND := 0.5
## Fog in and above the roof layer glows with the light source.
const SUN_HAZE := Color(0.3, 0.24, 0.27)
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
	return ABOVE_FOG.lerp(below_color(depth_layers), _below(depth_layers))


## Fog colour below the roof layer for a player at this depth (darker deeper down).
static func below_color(depth_layers: float) -> Color:
	return BELOW_FOG.lerp(DEEP_FOG, 1.0 - openness(depth_layers))


## Fog density per metre below the roof layer for a player at this depth (heavier deeper down).
static func below_density(depth_layers: float) -> float:
	return BELOW_DENSITY + DEEP_EXTRA_DENSITY * (1.0 - openness(depth_layers))


## How far a point `depth_layers` below the roof surface is into the fog sea (0 above, 1 below).
static func sea(depth_layers: float) -> float:
	return smoothstep(FOG_SEA_DEPTH - FOG_SEA_BAND, FOG_SEA_DEPTH + FOG_SEA_BAND, depth_layers)


## Fog density per metre at a point `depth_layers` below the roof surface, where the fog below
## the roof layer has density `below`: a light haze in the sunlit roof layer, the heavy fog sea
## from its bottom down, clearing quickly above the roof. Mirrors city_fog.gdshader.
static func local_density(depth_layers: float, below: float) -> float:
	if depth_layers >= 0.0:
		return lerpf(ABOVE_DENSITY, below, sea(depth_layers))
	return ABOVE_DENSITY * exp(depth_layers / CLEAR_LAYERS)


## Fog density per metre where the player is.
static func fog_density(depth_layers: float) -> float:
	return local_density(depth_layers, below_density(depth_layers))


static func ambient_energy(_depth_layers: float = 0.0) -> float:
	return AMBIENT


## Energy of the light source (it is masked per surface by sun_visibility()).
static func light_energy(_depth_layers: float = 0.0) -> float:
	return SUN_ENERGY


## How much sunlight reaches a surface `metres` above the bottom of the roof layer.
## Mirrors the `light()` mask in the block and bridge shaders.
static func sun_visibility(metres_above_roof_bottom: float) -> float:
	return smoothstep(-SUN_FADE_M, SUN_FADE_M, metres_above_roof_bottom)
