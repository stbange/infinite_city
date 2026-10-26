# Tasks

## 1. Pose mapping (spec: portal-traversal)

- [ ] 1.1 Write `test/unit/test_portal_math.gd` (pairing scenarios, crossing front/back/outside); verify it fails
- [ ] 1.2 Implement `src/core/portal_math.gd`; verify `scripts/test.sh -gselect=portal_math` passes

## 2. Doorways and pocket spaces (specs: pocket-doorways, pocket-spaces)

- [ ] 2.1 Write `test/unit/test_pocket_layout.gd` for every pocket-doorways scenario and the size, kind, determinism and inner-door scenarios of pocket-spaces; verify it fails
- [ ] 2.2 Implement `src/core/doorway_info.gd`, `src/core/pocket_space_info.gd` and `src/core/pocket_layout.gd`; verify `-gselect=pocket_layout` passes
- [ ] 2.3 Extend `test/unit/test_location_info.gd` with "Read-out inside"; implement `LocationInfo.describe_pocket()`; verify it passes

## 3. Streaming focus (spec: world-streaming)

- [ ] 3.1 Add "City stays loaded while inside" and "Origin follows the camera" to `test/integration/test_city_world.gd`; verify they fail
- [ ] 3.2 Add `streaming_focus` to `CityWorld`; verify `-gselect=city_world` passes

## 4. Scene nodes (specs: pocket-spaces, portal-traversal)

- [ ] 4.1 Write `test/integration/test_pocket_manager.gd` (doorway views per chunk, activation and release, out of sight, portal camera poses, entering, leaving, one-sided crossing, focus override while inside); verify it fails
- [ ] 4.2 Implement `src/world/doorway_view.gd`, `src/world/pocket_interior.gd`, `src/world/pocket_manager.gd`, the portal and pocket shaders, and wire doorways into `ChunkView`/`CityWorld`; verify `-gselect=pocket_manager` passes
- [ ] 4.3 Add `PocketManager` to `main.tscn`, the pocket read-out to `Hud`, and `--doorway`/`--inside` options to the screenshot tool; verify the main-scene tests still pass

## 5. Visual check and integration

- [ ] 5.1 Render screenshots under Xvfb: a doorway seen from outside showing its interior, and the view from inside looking back at the city; verify both by eye
- [ ] 5.2 Run `scripts/test.sh` (all green) and `openspec validate --all --strict` (no issues)

## Workflow follow-up

- Archive the change with `openspec archive add-pocket-doorways` once the review is done.
