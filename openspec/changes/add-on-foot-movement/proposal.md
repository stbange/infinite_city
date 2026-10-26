# Proposal: add-on-foot-movement

## Why

The city is meant to be lived in, not only flown over: the player wants to walk along bridges,
stand on roofs, step through doorways and — next — enter flats and rooms. That needs a body with
gravity and a city that is solid where the player is.

## What Changes

- A first-person **player body** replaces the fly camera. It walks (4.5 m/s), sprints (8 m/s),
  jumps (about 1.1 m) and falls under gravity; free flight stays available as a toggle (F).
- **Solid city near the player:** blocks and bridges within one chunk of the player collide;
  bridges get railings 1.1 m high on both edges (drawn and solid).
- **Fall safety net:** the city has no bottom, so a fall that lasts longer than 4 s puts the
  player back where they last stood.
- **Walking through magic doorways:** the block's solid shape leaves a 1 m deep opening at its
  magic doorway, and pocket spaces are solid (floor, walls, pillars, props) with their inner door open.
- The game **starts on foot** on a sunlit roof at the rim of the shaft nearest the origin.

Out of scope (later changes):
- Entering blocks through ordinary doors, rooms, stairs → `add-block-interiors`.
- Lifts, ladders, swimming, climbing, crouching; third-person view.

## Capabilities

### New Capabilities
- `on-foot-movement`: walking, sprinting, jumping, gravity, solid surroundings, railings, the
  fall safety net, the walk/fly toggle and the on-foot start.

### Modified Capabilities
- `free-flight`: the flight start point is used when the game starts in flight mode.
- `portal-traversal`: magic doorways can be walked through.
- `pocket-spaces`: pocket spaces are solid.
- `city-rendering`: bridges are drawn with railings.

## Impact

- New pure logic: `src/core/walk_model.gd`, `src/core/fall_guard.gd`; `SpawnFinder.find_on_foot()`.
- New scene code: `src/world/player.gd` (replaces `fly_camera.gd`), collision in `ChunkView`
  and `PocketInterior`, railings in `ChunkView`; `CityWorld` enables collision near the player;
  `PocketManager`, `Hud`, `CityLights`, `ScreenshotCapture` and `main.tscn` use the player.
- New input actions: `toggle_fly` (F).
