# Design: add-cyberpunk-atmosphere

## Context

Blocks and bridges are drawn by `ChunkView` with the `block`/`bridge` shaders; `CityWorld` drives
the environment from `Atmosphere` every tick. The directional light currently lights everything
(no shadows over kilometres of city), and ambient light is generous. Requirements: the two spec
deltas. Must work in Forward+ and Compatibility.

## Goals / Non-Goals

**Goals:** dark and moody below the roof, readable through emissive light; the sun visibly ends at
the roof layer; all new placement rules pure and unit-tested.

**Non-Goals:** shadow maps, volumetric fog (Forward+ only, cannot be verified headless), rain.

## Decisions

### D1 — Sunlight masked in the shaders, not by shadows
Shadow maps cannot cover a city this size. Instead the `block` and `bridge` shaders implement
`light()`: directional light is multiplied by `sun_visibility = smoothstep(-16, 16, y - roof_bottom)`
(the same formula as `Atmosphere.sun_visibility()`, which the tests pin), other lights are plain
Lambert + Blinn-Phong. `CityWorld` updates the uniform `roof_bottom_y` (scene space) on rebase.
A matching "skylight" emission (`albedo × 0.1 × sun_visibility`) replaces ambient light on the roof
layer. Visual layers: 1 = city outside, 2 = pocket spaces, 3 (bit value 4) = building interiors;
the sun's `light_cull_mask` is layer 1 only.

### D2 — Atmosphere as pure functions (`src/core/atmosphere.gd`)
`fog_density(depth)`: 0.0025 above the roof blending to 0.008 by one layer down, +0.002 towards the
deep. `fog_color(depth)`: dusk blue above, dark violet-indigo below, darker deep. `ambient_energy()`
is a constant 0.04. Exponential fog (not depth fog) gives the soft, thick falloff; at 760 m it
leaves < 1% so the streaming edge stays hidden.

### D3 — Signs and lamps generated per block / bridge (`src/core/city_lighting.gd`)
`CityLighting.signs_of(block, doorway)` draws a count by function, then for each sign up to 8
attempts: face, orientation (vertical 1.5–3 × 6–14 m or horizontal 6–14 × 1.5–3 m), position;
rejected if it leaves the face margin, enters the ±8 m band around the cell centre line, hits the
magic doorway or another sign. Seeded by `(seed, SALT_SIGNS, cell)`. No bridge queries are
needed because the band covers every possible bridge/entrance position.
`lamps_of(bridge)` is pure geometry (no randomness except colour).
Positions are relative to the owning cell centre, like all generated geometry.

### D4 — `LightPool` selection with hysteresis (`src/core/light_pool.gd`)
Anchors (`LightAnchor`: stable id, scene position, colour, energy, range) are gathered from chunk
views within one chunk of the camera. `LightPool.select()` keeps already-chosen anchors unless a
candidate is ≥ 10 m closer than the farthest chosen one. `CityLights` (`src/world/city_lights.gd`)
owns 12 `OmniLight3D`s (no shadows, cull mask city + interiors) and re-targets them 5× per second.
Compatibility caps lights per object at 8; that is acceptable — emissive surfaces carry the look.

### D5 — Facade restyle in `block.gdshader`
Dark base (mostly grey, 12% function colour); glowing roofline band and corner strips in the
function colour (half of the blocks). Window grid is now world-aligned (4 m floors, 4 m bays,
measured from the block's own minimum corner so the lit pattern is stable across rebases) —
in preparation for real interiors whose windows must line up. Lit-window palette gains magenta
and teal.

### D6 — Neon shader (`src/world/shaders/neon.gdshader`)
Unshaded emission: a tube border plus hashed glyph strokes inside, colour per instance; flickering
signs drop out briefly using a time hash. Drawn as one MultiMesh per chunk; lamp posts and heads
as two more.

## Risks / Trade-offs

- [Custom `light()`] Loses Godot's default BRDF on blocks and bridges → simple Lambert/Blinn is
  enough for matte concrete; revisit if PBR detail is needed.
- [Generation cost] Signs add ~1 hash stream per block → negligible next to block generation.
- [Light pool popping] Lights re-target at most 5×/s with hysteresis; new lights fade in over
  0.3 s to hide the switch.
