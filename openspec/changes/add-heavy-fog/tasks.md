# Tasks

## 1. Atmosphere rules (specs: city-fog, city-rendering)

- [x] 1.1 Update `test/unit/test_atmosphere.gd`: "Dense fog below the roof" (0.018), "Heavier deeper down", "Light haze on the roof", "Clearing above the roof"; verify they fail
- [x] 1.2 Implement `below_density()`, `below_color()`, `local_density()`, `CLEAR_LAYERS`, `SUN_HAZE` and heavier densities in `Atmosphere`; verify `-gselect=atmosphere` passes

## 2. Fog node and shader (spec: city-fog)

- [x] 2.1 Write `test/unit/test_city_fog.gd` ("Banks stay put when the origin moves") and `test/integration/test_city_fog.gd` ("The shader follows the same rule", "Haze colour", "Banks and wind", "Clear inside an entered block", "Outside", "Inside a pocket space", "No double fog"); move the main-scene fog test there; verify they fail
- [x] 2.2 Implement `city_fog.gdshader`, `CityFog`, `RenderLayers.FOG`, portal camera layers and the `main.tscn` wiring; verify `-gselect=fog` passes

## 3. Visual check and integration

- [x] 3.1 Render a canyon, the roof, a bridge entrance, a window view and the start on foot; verify by eye (heavy fog, sunlit haze on top, clear rooms, no artefacts)
- [ ] 3.2 Re-render the README screenshots
- [x] 3.3 Run `scripts/test.sh` (all green) and `openspec validate --all --strict`
