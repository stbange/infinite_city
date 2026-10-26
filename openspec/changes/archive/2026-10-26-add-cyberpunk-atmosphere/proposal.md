# Proposal: add-cyberpunk-atmosphere

## Why

The city should feel like cyberpunk in blockspace: dark, moody and foggy. Daylight from the light
source above should only touch the uppermost layer; below it, the city lives on artificial light
alone — windows, neon signs and lamps. Today every surface is lit by the sun, ambient light is
generous and the fog is thin, so the deep city looks flat and evenly lit.

## What Changes

- **Sunlight only on the uppermost layer:** surfaces in the roof layer and above receive light
  from the light source; it fades out within 16 m below the bottom of the roof layer and is absent
  everywhere deeper. Building and pocket interiors never receive it.
- **Dark, foggy atmosphere:** ambient light is near zero everywhere; below the roof the fog
  limits visibility to under 400 m and darkens with depth; above the roof it is thinner.
- **Neon signs:** blocks carry glowing signs in a neon palette on their facades — markets the
  most, every essential service one in its own colour — some flickering. Signs keep clear of the
  bridge band and of magic doorways.
- **Bridge lamps:** lamps along both edges of every bridge.
- **Dark facades:** blocks become dark concrete; their function colour shows as glowing accent
  strips; lit windows use a wider neon-tinted palette.
- **Real lights near the player:** a small pool of real light sources follows the player to the
  nearest signs and lamps, so nearby surfaces are actually lit.

Out of scope (later changes):
- Walking and collision → `add-on-foot-movement`.
- Interior lighting of rooms → `add-block-interiors`.
- Rain, volumetric light shafts, flying traffic lights → later.

## Capabilities

### New Capabilities
- `city-lighting`: where light comes from — the sunlit uppermost layer, darkness below, neon
  signs, bridge lamps and the nearby real-light pool.

### Modified Capabilities
- `city-rendering`: "Depth atmosphere" becomes dark and foggy with limited visibility below the roof.

## Impact

- New pure logic: `src/core/city_lighting.gd` (signs, lamps), `src/core/sign_info.gd`,
  `src/core/lamp_info.gd`, `src/core/light_anchor.gd`, `src/core/light_pool.gd`;
  `src/core/atmosphere.gd` reworked.
- Scene code: `ChunkView` (signs and lamps), `CityWorld` (atmosphere, shader uniforms),
  new `src/world/city_lights.gd`; shaders `block`, `bridge` (masked sunlight, dark facades),
  new `neon.gdshader`; `main.tscn` environment.
- Tests: new unit tests, updated atmosphere tests, integration tests for chunk views and lights.
