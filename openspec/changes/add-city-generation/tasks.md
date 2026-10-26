# Tasks

## 1. Deterministic primitives

- [x] 1.1 Write `test/unit/test_int_math.gd` (floored division/modulo for negative values) and verify it fails
- [x] 1.2 Implement `src/core/int_math.gd` and verify `scripts/test.sh -gselect=int_math` passes
- [x] 1.3 Write `test/unit/test_det_hash.gd` with golden MurmurHash3 values from a Python reference, negative-coordinate handling and u01 range; verify it fails
- [x] 1.4 Implement `src/core/det_hash.gd` and verify `scripts/test.sh -gselect=det_hash` passes
- [x] 1.5 Write `test/unit/test_cell_random.gd` (same seed → same sequence, range bounds, rough uniformity) and verify it fails
- [x] 1.6 Implement `src/core/cell_random.gd` and verify `scripts/test.sh -gselect=cell_random` passes

## 2. Configuration and lattice

- [x] 2.1 Write `test/unit/test_city_config.gd` (defaults valid, invalid values reported) and the lattice scenarios (cell bounds, negative positions) in `test/unit/test_city_lattice.gd`; verify they fail
- [x] 2.2 Implement `src/core/city_config.gd`, `src/core/block_types.gd` and lattice helpers in `src/core/city_layout.gd`; verify both test files pass

## 3. Boundary, density and canyons (spec: city-layout)

- [x] 3.1 Write `test/unit/test_city_bounds.gd` for "Upper boundary", "Sparse sky layers", "Dense roof", "Unbounded below and sideways" and "Block density"; verify it fails
- [x] 3.2 Write `test/unit/test_canyons.gd` for "Vertical shafts", "Horizontal canyons" and "Plazas"; verify it fails
- [x] 3.3 Implement occupancy, shafts, canyons and plazas in `CityLayout`; verify `scripts/test.sh -gselect=city_bounds` and `-gselect=canyons` pass

## 4. Blocks and zoning (specs: city-layout, city-zoning)

- [x] 4.1 Write `test/unit/test_block_geometry.gd` for "Block geometry" and `test/unit/test_zoning.gd` for all city-zoning scenarios; verify they fail
- [x] 4.2 Implement `BlockInfo`, block geometry, district plans and depth-band function tables; verify `-gselect=block_geometry` and `-gselect=zoning` pass

## 5. Bridges and chunks (specs: city-bridges, city-layout)

- [x] 5.1 Write `test/unit/test_bridges.gd` for all city-bridges scenarios and `test/unit/test_chunk_generation.gd` for "Chunk generation" and "Deterministic generation"; verify they fail
- [x] 5.2 Implement `BridgeInfo`, `ChunkData`, `bridge_between()`, `bridges_of()` and `generate_chunk()`; verify `-gselect=bridges` and `-gselect=chunk_generation` pass
- [x] 5.3 Add a chunk-generation timing check to `test/unit/test_chunk_generation.gd` that prints the average time per chunk and fails above 50 ms; verify it passes

## 6. Integration check

- [x] 6.1 Run `scripts/test.sh` (all green) and `openspec validate --all --strict` (no issues)

## Workflow follow-up

- Archive the change with `openspec archive add-city-generation` once the review is done.
