# Design: add-on-foot-movement

## Context

Today a `FlyCamera` (Node3D) drives streaming, rebasing, pocket crossings, the HUD and the light
pool. Nothing in the city collides. Requirements: the spec deltas of this change.

## Goals / Non-Goals

**Goals:** solid, walkable surroundings; movement rules pure and unit-tested; physics tested in
integration tests with real `CharacterBody3D` physics.

**Non-Goals:** entering blocks (next change), animations, third person.

## Decisions

### D1 — One `Player` (CharacterBody3D) with two modes (`src/world/player.gd`)
`Player` replaces `FlyCamera` and keeps its interface (`yaw`, `pitch`, `set_view()`, `camera`,
`model`, `input_enabled`) so streaming, pockets, HUD and lights keep working. The body origin is
at the feet; the camera sits 1.65 m above. Mode `WALK` integrates `WalkModel` and calls
`move_and_slide()`; mode `FLY` disables the capsule and moves with `FlightModel` (noclip).
Inputs can be scripted (`move_input`, `wants_jump`, `wants_sprint`) when `input_enabled` is
false — used by tests and the screenshot tool.

### D2 — `WalkModel` and `FallGuard` are pure (`src/core/`)
`WalkModel.step(velocity, yaw, input, sprint, jump, on_floor, delta)` returns the new velocity:
horizontal velocity approaches the target (4.5 or 8 m/s along the yaw-only basis) with
acceleration 60 m/s² on the ground and 10 m/s² in the air; jump sets vy = 4.6 on the ground;
gravity 9.81. `FallGuard.update(on_floor, position, delta)` remembers the last ground position
(only after 0.3 s of steady standing, so ledges are not recorded mid-step) and reports a reset
after 4 s in the air.

### D3 — Colliders per chunk, built on demand (`ChunkView.set_collision_enabled()`)
Each `ChunkView` keeps its generated data and builds one `StaticBody3D` with `BoxShape3D`s for
its blocks, decks and railings when `CityWorld` enables collision for chunks within one chunk of
the player (27 chunks, ≈ 2 000 boxes); farther chunks drop their bodies. Rebasing moves the
`ChunkView` and therefore its body. Blocks with a magic doorway get their box shrunk by 1 m on
the doorway face plus four slabs framing the opening, leaving a 1 m deep walkable gap.
Shapes per block are kept by cell so the next change can swap a block's box for its interior.

### D4 — Crossings at the eyes
`PocketManager` tests crossings with `player.camera.global_position` and maps the body transform
and its velocity through the pair (the mapping is a rigid yaw + translation, so the camera keeps
its offset). `place_camera_before()` places the eyes, not the feet.

### D5 — Pocket spaces get colliders (`PocketInterior`)
A `StaticBody3D` with floor and ceiling slabs, four wall slabs (the entrance wall as three boxes
around the 4 m × 6 m opening), pillars, props, tree trunks (not crowns) and the monument.

### D6 — Railings
Two thin boxes (0.08 m × 1.1 m) per deck edge, drawn as a MultiMesh with a glowing top strip
and added to the chunk collider.

## Risks / Trade-offs

- [Collider build hitches] ~85 boxes per chunk built in GDScript; at most a few chunks change
  per tick when walking → negligible; flying fast with collision off builds nothing.
- [Fall into a shaft] Shafts are bottomless → the fall guard resets after 4 s by design.
- [Breaking change] `FlyCamera` is removed; tests move to `Player` in fly mode.
