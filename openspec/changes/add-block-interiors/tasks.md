# Tasks

## 1. Floor grid (specs: city-layout, city-bridges)

- [x] 1.1 Add "Blocks on the floor grid" to `test/unit/test_block_geometry.gd` and "Deck on the cell centre line and the floor grid" to `test/unit/test_bridges.gd`; verify they fail
- [x] 1.2 Snap block heights and bridge decks in `CityLayout`; verify the whole suite stays green

## 2. Plans (spec: block-interiors)

- [x] 2.1 Write `test/unit/test_interior_plan.gd` ("Floor levels", "Corridor cross", "Units and doors", "Entrances at bridges", determinism); verify it fails
- [x] 2.2 Implement `InteriorPlan`, `InteriorUnit`, `EntranceInfo` and `InteriorLayout.plan_of()`; verify `-gselect=interior_plan` passes

## 3. Floors and furnishing (spec: block-interiors)

- [x] 3.1 Write `test/unit/test_interior_floor.gd` ("Flights per floor", "Roof access", "Window grid", "Furnished flats", "Signature items", "Nothing in the way", "Lit rooms", determinism); verify it fails
- [x] 3.2 Implement `InteriorFloor`, `RoomInfo`, `Furnisher` and `InteriorLayout.floor_of()`; verify `-gselect=interior_floor` passes

## 4. Entering blocks (spec: block-interiors)

- [ ] 4.1 Write `test/integration/test_interiors.gd` ("Approaching a block", "Walking in", "Leaving", "Up the first flight", "Read-out in a room"); verify it fails
- [ ] 4.2 Implement `InteriorView`, `InteriorManager`, `facade.gdshader`, `ChunkView.set_block_hidden()`, room light anchors, HUD read-out and wire them into `main.tscn`; verify the tests pass

## 5. Visual check and integration

- [ ] 5.1 Render screenshots: walking up to an entrance, a corridor, a furnished flat, a shop or farm unit, the view out of a window; verify by eye
- [ ] 5.2 Run `scripts/test.sh` (all green) and `openspec validate --all --strict`

## Workflow follow-up

- Archive with `openspec archive add-block-interiors` after review.
