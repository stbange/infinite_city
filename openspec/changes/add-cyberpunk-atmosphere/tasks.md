# Tasks

## 1. Atmosphere and sunlight (specs: city-rendering, city-lighting)

- [ ] 1.1 Update `test/unit/test_atmosphere.gd` for the modified "Depth atmosphere" scenarios and add "Sunlight only on the uppermost layer" and "Dark ambience"; verify the new ones fail
- [ ] 1.2 Rework `src/core/atmosphere.gd`; verify `scripts/test.sh -gselect=atmosphere` passes

## 2. Signs and lamps (spec: city-lighting)

- [ ] 2.1 Write `test/unit/test_city_lighting.gd` for "Neon signs", "Sign placement" and "Bridge lamps"; verify it fails
- [ ] 2.2 Implement `src/core/sign_info.gd`, `src/core/lamp_info.gd` and `src/core/city_lighting.gd`; verify `-gselect=city_lighting` passes

## 3. Light pool (spec: city-lighting)

- [ ] 3.1 Write `test/unit/test_light_pool.gd` for "Real light near the player"; verify it fails
- [ ] 3.2 Implement `src/core/light_anchor.gd` and `src/core/light_pool.gd`; verify `-gselect=light_pool` passes

## 4. Scene integration (specs: city-lighting, city-rendering)

- [ ] 4.1 Extend `test/integration/test_chunk_view.gd` (signs and lamps drawn per chunk, anchors exposed), `test/integration/test_city_world.gd` (roof uniform, fog density applied) and `test/integration/test_main_scene.gd` ("Light layers", light pool exists); verify they fail
- [ ] 4.2 Implement neon shader, sign/lamp drawing in `ChunkView`, `CityLighting` in `CityWorld`, `src/world/city_lights.gd`, masked sunlight and facade restyle in the block/bridge shaders, and the new environment in `main.tscn`; verify the tests pass

## 5. Visual check and integration

- [ ] 5.1 Render screenshots (roof, canyon, deep, shaft) and verify by eye: sunlit roof layer only, dark foggy depths, neon signs and lamps
- [ ] 5.2 Run `scripts/test.sh` (all green) and `openspec validate --all --strict`

## Workflow follow-up

- Archive with `openspec archive add-cyberpunk-atmosphere` after review.
