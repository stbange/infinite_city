# Tasks

## 1. Streets and lanes (spec: city-layout)

- [x] 1.1 Update `test/unit/test_block_geometry.gd` ("Blocks stay inside their cells", "Narrow streets", "Block sizes vary", "Blocks on the floor grid"), add `test/unit/test_lanes.gd` ("Lane frequency", "A lane runs without end", "Same lanes for every generator"), update density and config tests; verify they fail
- [x] 1.2 Implement the setbacks, `is_lane()`, new config fields and densities; verify the city-layout tests pass

## 2. Integration and visual check

- [x] 2.1 Run `scripts/test.sh`; fix any other spec's tests that relied on the old spacing
- [x] 2.2 Render a street, an avenue (lane), the roof and an interior; verify by eye; re-render README screenshots and update numbers
- [x] 2.3 Run `scripts/test.sh` (all green) and `openspec validate --all --strict`
