# Design: add-world-streaming

## Context

`CityLayout` (archived change `add-city-generation`) generates any chunk in ~2 ms of GDScript and
stores block geometry relative to cell centres. Requirements: the four spec deltas of this change.
The renderer must also work in the Compatibility renderer (used for headless screenshots under
Xvfb/llvmpipe).

## Goals / Non-Goals

**Goals:**
- A smooth flythrough at 60 fps with ~300 chunks (≈ 12 000 blocks) loaded.
- Identical precision at the roof and at depth 10 000 000.
- Every rule that can be pure logic is pure logic, so it is unit-tested without a scene tree.

**Non-Goals:**
- Collision and physics bodies for blocks.
- Worker threads (generation stays on the main thread with a budget; see Risks).
- Final art. Boxes with procedural windows are the placeholder look.

## Decisions

### D1 — `StreamingPlanner` with a pre-sorted offset table (`src/core/streaming_planner.gd`)
All offsets inside the ellipsoid are computed once and sorted by normalised distance, ties broken
by (|dy|, dy, dx, dz) so the order is total and deterministic. `load_order(focus)` = offsets +
focus, dropping chunks above `top_chunk_y = floor((roof + sky_layers) / chunk_cells)`.
`next_loads(focus, loaded, budget)` walks that order; `to_unload(focus, loaded)` uses the
enlarged ellipsoid (H + 1, V + 1). *Alternative:* a cube region — simpler but ~2× as many chunks
for the same visible distance.

### D2 — `FloatingOrigin` with an integer origin chunk (`src/core/floating_origin.gd`)
`origin_chunk: Vector3i`. Scene positions of cells/chunks are computed from *integer differences*
(`cell - origin_cell`) before converting to float, so they are exact for any absolute coordinate.
`rebase_delta(camera_pos)` returns `floor(camera_pos / chunk_size)` when any axis exceeds 512 m.
Absolute metres are reported per axis as GDScript `float` (64-bit) for tests and the HUD.
*Alternative:* Godot double-precision build — requires custom engine builds for every platform,
and still needs integer identity for generation.

### D3 — `CityWorld` node owns streaming and rebasing (`src/world/city_world.gd`)
`tick()` (called from `_process`, and directly by tests) does: rebase if needed → unload → load
up to the budget. On rebase, every node in group `world_anchored` is moved by `-delta × chunk_size`
and every `ChunkView` is re-placed from its integer chunk coordinate (no drift accumulates).
Emits `origin_shifted(delta: Vector3i)` and `chunk_loaded/unloaded`. Empty chunks are recorded as
loaded with no node.

### D4 — `ChunkView` uses two `MultiMeshInstance3D`s (`src/world/chunk_view.gd`)
One for blocks (unit `BoxMesh`, instance basis scaled to the block size, instance colour = function
colour, custom data = per-block window seed) and one for bridge decks (unit box scaled to length ×
1.2 m × width). Materials are shared statics so all chunks batch into few draw calls.

### D5 — Shaders (`src/world/shaders/block.gdshader`, `bridge.gdshader`, `space_sky.gdshader`)
Block shader: albedo from instance colour; procedural window grid on side faces in metres
(object-local position × instance scale), lit windows chosen by hashing window index + seed;
albedo darkens and window glow strengthens with depth below the roof (uniform `roof_y`, updated
on rebase). Sky shader: near-black space with hashed stars and a bright disc in the light's
direction — the light source above the roof.

### D6 — `Atmosphere` is a pure function of depth (`src/core/atmosphere.gd`)
`fog_color(depth_layers)`, `ambient_energy(depth_layers)`: brightness =
`min + (top - min) × exp(-max(depth, 0) / 80)`. `CityWorld` applies it to the `Environment`
every frame (depth fog from 350 m to 1000 m hides the streaming edge).

### D7 — `FlightModel` and `SpawnFinder` are pure (`src/core/flight_model.gd`, `src/core/spawn_finder.gd`)
`FlightModel.velocity(yaw, pitch, input, boost)` flies along the full view direction for
forward/back, along the yaw-only right vector for strafing, and along world +Y for up/down; the
combined direction is normalised. `apply_mouse()` clamps pitch to ±89°. `SpawnFinder` searches
district columns in rings around (0, 0) for the nearest shaft and returns a cell 2 layers above
the roof at the shaft's rim plus yaw/pitch facing the shaft centre.
`FlyCamera` (`src/world/fly_camera.gd`) only maps `Input` actions to these functions.

### D8 — `LocationInfo` formats the read-out (`src/core/location_info.gd`)
Pure function of (layout, cell, block kind); `Hud` (`src/world/hud.gd`) displays it plus a colour
legend and control hints.

### D9 — Screenshot tooling
`src/world/screenshot_capture.gd` reads `--screenshot=<png> --pos=x,y,z --yaw=deg --pitch=deg`
from the user command-line args, waits until streaming is complete plus a few frames, saves the
viewport and quits. `scripts/screenshot.sh` runs it under `xvfb-run` with
`--rendering-method gl_compatibility`.

## Risks / Trade-offs

- [Main-thread generation hitches] 4 chunks × ~2 ms = ~8 ms per frame while moving fast →
  budget is configurable; follow-up: per-thread `CityLayout` instances on `WorkerThreadPool`.
- [No occlusion of the light] The directional light has no shadows (too large an area), so depth
  is conveyed by the atmosphere and shader darkening instead of real occlusion.
- [Rebase cost] Re-placing ~300 chunk nodes is cheap (< 1 ms) and happens at most every ~500 m.
- [Float precision] Only differences of integer coordinates are converted to float (D2), and the
  camera stays within 522 m of the origin, so float32 error stays below 0.1 mm.
