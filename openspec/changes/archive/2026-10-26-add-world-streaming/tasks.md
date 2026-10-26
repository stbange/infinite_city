# Tasks

## 1. Streaming planner (spec: world-streaming)

- [x] 1.1 Write `test/unit/test_streaming_planner.gd` covering every world-streaming scenario; verify it fails
- [x] 1.2 Implement `src/core/streaming_planner.gd`; verify `scripts/test.sh -gselect=streaming_planner` passes

## 2. Floating origin (spec: floating-origin)

- [x] 2.1 Write `test/unit/test_floating_origin.gd` covering every floating-origin scenario (long flight simulated in pure logic); verify it fails
- [x] 2.2 Implement `src/core/floating_origin.gd`; verify `scripts/test.sh -gselect=floating_origin` passes

## 3. Flight, spawn, read-out and atmosphere logic (specs: free-flight, city-rendering)

- [x] 3.1 Write `test/unit/test_flight_model.gd`, `test/unit/test_spawn_finder.gd`, `test/unit/test_location_info.gd` and `test/unit/test_atmosphere.gd`; verify they fail
- [x] 3.2 Implement `src/core/flight_model.gd`, `src/core/spawn_finder.gd`, `src/core/location_info.gd` and `src/core/atmosphere.gd`; verify the four test files pass

## 4. Scene nodes (specs: city-rendering, world-streaming, floating-origin)

- [x] 4.1 Write `test/integration/test_chunk_view.gd` ("One box per block", "Function colours", "One deck per bridge"); verify it fails
- [x] 4.2 Implement `src/world/chunk_view.gd` and the block/bridge shaders; verify `-gselect=chunk_view` passes
- [x] 4.3 Write `test/integration/test_city_world.gd` (budgeted loading in a scene, region fills up, rebase keeps chunks and anchored nodes in place); verify it fails
- [x] 4.4 Implement `src/world/city_world.gd`; verify `-gselect=city_world` passes

## 5. Playable scene (specs: free-flight, city-rendering)

- [x] 5.1 Write `test/integration/test_main_scene.gd` (scene loads, exactly one downward directional light, camera starts at the spawn point, HUD shows the read-out); verify it fails
- [x] 5.2 Implement `src/world/fly_camera.gd`, `src/world/hud.gd`, `src/world/shaders/space_sky.gdshader` and `src/scenes/main.tscn`; verify `-gselect=main_scene` passes
- [x] 5.3 Implement `src/world/screenshot_capture.gd` and `scripts/screenshot.sh`; verify a PNG of the start view is produced under Xvfb and shows roof, shaft and sky

## 6. Integration check

- [x] 6.1 Run `scripts/test.sh` (all green) and `openspec validate --all --strict` (no issues)

## Workflow follow-up

- Archive the change with `openspec archive add-world-streaming` once the review is done.
