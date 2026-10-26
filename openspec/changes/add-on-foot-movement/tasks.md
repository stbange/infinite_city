# Tasks

## 1. Movement rules (spec: on-foot-movement)

- [ ] 1.1 Write `test/unit/test_walk_model.gd` ("Walking", "Sprinting", "Jumping and gravity") and `test/unit/test_fall_guard.gd` ("Fall safety net"); verify they fail
- [ ] 1.2 Implement `src/core/walk_model.gd` and `src/core/fall_guard.gd`; verify both pass
- [ ] 1.3 Add "On-foot start" to `test/unit/test_spawn_finder.gd`; implement `SpawnFinder.find_on_foot()`; verify it passes

## 2. Player body (specs: on-foot-movement, free-flight)

- [ ] 2.1 Write `test/integration/test_player.gd` (walk/fly toggle, flight ignores walls, standing on a deck, walls stop the player, railings hold the player, fall safety net with a short timeout); verify it fails
- [ ] 2.2 Implement `src/world/player.gd`, chunk collision and railings in `ChunkView`, collision enabling in `CityWorld`, the `toggle_fly` input; replace `FlyCamera` in `PocketManager`, `Hud`, `CityLights`, `ScreenshotCapture`, `main.tscn` and the existing tests; verify `-gselect=player` and the existing suites pass

## 3. Doorways and pocket spaces on foot (specs: portal-traversal, pocket-spaces, city-rendering)

- [ ] 3.1 Add "Walking into a doorway", "Standing in a pocket space", "The inner door is open" and "Two railings per deck" tests; verify they fail
- [ ] 3.2 Implement the doorway gap in block colliders, eye-based crossings with velocity mapping, `PocketInterior` colliders, and railing drawing; verify the tests pass

## 4. Visual check and integration

- [ ] 4.1 Render on-foot screenshots (start on the roof, on a bridge) and verify by eye
- [ ] 4.2 Run `scripts/test.sh` (all green) and `openspec validate --all --strict`

## Workflow follow-up

- Archive with `openspec archive add-on-foot-movement` after review.
