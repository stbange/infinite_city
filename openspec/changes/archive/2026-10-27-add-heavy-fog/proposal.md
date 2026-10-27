# Proposal: add-heavy-fog

## Why

The city should be swallowed by heavy fog: neon and lit windows close by, silhouettes a little
further, and nothing but glowing violet murk beyond. Today the built-in environment fog is a
light, uniform haze (visibility about 400 m): distant blocks stay sharp, the fog does not move,
it does not know where the sunlit top layer is, and it fills the inside of buildings and pocket
spaces just like the open air.

## What Changes

- **Heavy fog as a shader:** a full-screen fog pass reads the depth buffer and marches along each
  view ray. Below the roof layer the fog is heavy (at least 0.018 per metre, so less than 5% of a
  surface shows through after about 170 m) and gets heavier deeper down.
- **Fog by height:** density and colour are evaluated per point along the ray: heavy below the
  roof layer, a light haze at the roof surface, clearing quickly above it so the light source
  stays visible. Fog in the uppermost layer is lit by the sun; deeper fog is dark violet.
- **Drifting banks:** the density varies in fog banks that drift with a slow wind; the banks are
  anchored to absolute world positions, so they do not jump when the floating origin moves.
- **Clear indoors:** no fog inside entered blocks or inside pocket spaces; the portal view of the
  city from inside a pocket space is fogged like the city itself.
- **Neon halos:** the environment's glow gets wider levels so lights bloom into the fog.
- The built-in environment fog is switched off so fog is not applied twice.

Out of scope (later changes):
- Volumetric light from individual lamps and signs (light shafts, cones) and rain.
- Shortening the streaming radius and camera range to what the fog lets through (performance).

## Capabilities

### New Capabilities
- `city-fog`: the heavy fog — density and colour by height, drifting banks, clear indoors, and
  which cameras draw it.

### Modified Capabilities
- `city-rendering`: "Depth atmosphere" requires heavy fog (at least 0.018 per metre below the roof
  layer, heavier deeper down) instead of at least 0.0075.

## Impact

- New: `src/world/city_fog.gd` (CityFog node), `src/world/shaders/city_fog.gdshader`.
- Changed: `Atmosphere` (heavier fog, `below_density()`, `below_color()`, `local_density()`,
  `CLEAR_LAYERS`, `SUN_HAZE`), `RenderLayers.FOG`, `PocketManager` (portal camera layers),
  `CityWorld` (no longer drives the environment fog), `main.tscn` (CityFog node, environment
  fog off, wider glow).
- Tests: `test_atmosphere.gd`, new `test_city_fog.gd` (unit) and `test/integration/test_city_fog.gd`.
