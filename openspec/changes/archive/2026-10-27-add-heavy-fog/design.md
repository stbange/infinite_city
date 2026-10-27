# Design: add-heavy-fog

## Context

The atmosphere is `Atmosphere` (pure: colours, densities, sun mask) driving the `Environment`'s
exponential fog from `CityWorld._apply_atmosphere()`. Built-in fog is one density for the whole
frame, cannot vary in space or move, and is applied per material in the Compatibility renderer.
Visuals must work in Forward+ and Compatibility.

## Goals / Non-Goals

**Goals:** heavy fog that varies with height (sunlit top layer, dark below, clearing above the
roof), drifts in banks, leaves building and pocket interiors clear, and looks the same through a
portal. Pure rules stay in `Atmosphere` and are unit-tested; the shader mirrors them.

**Non-Goals:** volumetric light per lamp, shadows in fog, rain.

## Decisions

### D1 — A full-screen fog pass (`city_fog.gdshader`)
A `QuadMesh` (2 × 2) whose vertex shader writes `POSITION = vec4(VERTEX.xy, 1, 1)` covers the
screen of whichever camera draws it. The fragment shader reads `hint_depth_texture`, rebuilds the
view-space point (Compatibility: `ndc = vec3(uv, depth) * 2 - 1`; Forward+: `vec3(uv * 2 - 1,
depth)`), and marches 12 jittered steps (interleaved gradient noise) from the camera's near plane
to the surface, at most 900 m. Per step: density from the point's height (D2) times the bank
noise (D3), colour from height; transmittance and in-scattered colour are accumulated and blended
over the frame with `ALPHA = 1 − transmittance`. Render mode: unshaded, no depth test or write,
`render_priority` maximum so it is drawn after other transparent surfaces (glass). The pass runs
before the environment's glow, so neon that survives the fog still blooms; the glow gets two wider
levels for soft halos.

Both renderers use reversed Z in Godot 4.7: the near plane is at clip-space z = 1 (found by
rendering distance bands; the documented Compatibility formula for the depth itself holds).
Screen-texture mipmaps are not available in Compatibility, so the fog does not blur the frame for
halos (a ring blur produced ghost copies); the glow does that instead.

### D2 — Density and colour by height (`Atmosphere.local_density()`)
The heavy fog is a "fog sea" whose surface lies at the roof layer's bottom (`FOG_SEA_DEPTH` = 1
layer below the roof surface), the height where the sunlight fades out, so the sunlit uppermost
layer stands clear above it. `sea(d) = smoothstep(1 − 0.5, 1 + 0.5, d)`.
`local_density(depth_layers, below)`: below the roof surface `lerp(ABOVE_DENSITY, below, sea)`;
above it `ABOVE_DENSITY · exp(depth_layers / CLEAR_LAYERS)` (0.0015, halving every ~22 m).
`below = below_density(player depth)` (0.02 + 0.004 · (1 − openness)). Colour: `ABOVE_FOG`
blending to `below_color(player depth)` with `sea`, plus `SUN_HAZE · sun_visibility(height above
the roof layer's bottom)`, so the top of the fog sea glows in the sunlight. (A first version
blended over the whole roof layer; it buried the sunlit layer and the sky in bright haze.)
`fog_density(depth)` (the density where the player is) becomes `local_density(depth,
below_density(depth))`. The shader takes the constants as uniforms set by `CityFog`, and an
integration test compares them, so the two cannot drift apart.

### D3 — Drifting banks anchored to the world
Two octaves of value noise (64 m and 16 m) with integer-lattice hashes taken modulo the period
(1024 m), so the noise tiles exactly. The sample point is `scene + noise_offset + wind · TIME`,
where `noise_offset` is the absolute position of the scene origin modulo 1024 m, computed exactly in
integers from the origin chunk (chunks are 256 m). A rebase changes scene positions and the offset
by the same amount, so banks stay where they are. The bank factor is `clamp(1 + 0.9 · (2n − 1),
0.05, 2)`; denser banks are drawn slightly brighter.

### D4 — Clear indoors and in pocket spaces
`CityFog` passes up to two clear boxes: the ready interiors from `InteriorManager` (block box plus
the slab under floor 0). The march starts where the ray leaves a box the camera is in, and points
inside any clear box have no density. Pocket spaces are clear by layers: `RenderLayers.FOG` (bit
4) is the quad's layer; `CityFog` clears it from the main camera's cull mask while the player is
inside a pocket space, and `PocketManager` gives the portal camera `CITY | INTERIOR | FOG` when it
shows the city from inside (its near plane at the far door makes the fog start there) and
`POCKET` otherwise.

### D5 — Files
- New: `src/world/city_fog.gd` (`CityFog`: quad on the player's camera, `refresh()` each frame,
  `noise_offset()`, `clear_boxes()`), `src/world/shaders/city_fog.gdshader`.
- Changed: `src/core/atmosphere.gd`, `src/core/render_layers.gd`, `src/world/pocket_manager.gd`,
  `src/world/city_world.gd` (stops driving environment fog), `src/scenes/main.tscn`.

## Risks / Trade-offs

- [GPU cost] 12 steps × 2 noise octaves per pixel: cheap on desktop GPUs; `steps` is a uniform.
- [Precision] Positions in the shader are scene positions (near the origin thanks to the floating
  origin); the noise offset is reduced modulo 1024 m in integers, so it stays exact at any depth.
- [Hidden city] Most of the streamed city is now invisible; shrinking the streaming radius is a
  later performance change.
- [Renderer conventions] The reversed-Z assumption is tied to Godot 4.7; it is isolated in two
  lines of the shader.
