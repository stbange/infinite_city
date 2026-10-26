# Proposal: add-world-streaming

## Why

The generator from `add-city-generation` can describe any part of the infinite city, but nothing
is visible yet. To see and explore it we need to load the city around the viewer as they move,
keep rendering precise no matter how far they travel (a 32-bit float is only accurate to
centimetres within a few kilometres of the origin), and give the player a way to fly through
it. This is also the proof that an infinite, bounded-above city is feasible in Godot.

## What Changes

- **Chunk streaming:** keep an ellipsoid of chunks (radius 4 chunks horizontally, 3 vertically)
  loaded around a focus point, nearest first, with a per-frame generation budget and unloading
  with hysteresis. Chunks above the city are never loaded.
- **Floating origin:** all scene positions are relative to an integer origin chunk; when the
  camera strays more than 512 m from the origin, the world is shifted back, so precision is the
  same at the roof and ten million layers down.
- **City rendering:** blocks drawn as boxes in their function's colour with lit windows,
  bridges drawn as decks, one light source above the roof, and an atmosphere that darkens with
  depth.
- **Free flight:** a spectator camera with six-degree-of-freedom flight, boost, mouse look and a
  location read-out (cell, depth below the roof, district, current block).
- A playable `main.tscn` and a screenshot tool for headless visual checks.

Out of scope (later changes):
- Collision, walking on bridges and gravity → a future `add-on-foot-movement`.
- Threaded chunk generation, level of detail beyond the streaming radius → future performance work.
- Doorways and pocket spaces → `add-pocket-doorways`.

## Capabilities

### New Capabilities
- `world-streaming`: which chunks are loaded around the focus point, in what order, how fast,
  and when they are released.
- `floating-origin`: how positions are expressed so precision never degrades with distance.
- `city-rendering`: how blocks, bridges, the light source and the depth atmosphere are shown.
- `free-flight`: how the player flies and how the current location is reported.

### Modified Capabilities
- None.

## Impact

- New pure logic: `src/core/streaming_planner.gd`, `src/core/floating_origin.gd`,
  `src/core/flight_model.gd`, `src/core/atmosphere.gd`, `src/core/location_info.gd`.
- New scene code: `src/world/city_world.gd`, `src/world/chunk_view.gd`,
  `src/world/fly_camera.gd`, `src/world/hud.gd`, shaders in `src/world/shaders/`,
  `src/scenes/main.tscn`.
- New tooling: `scripts/screenshot.sh`, `src/world/screenshot_capture.gd`.
- New unit and integration tests.
