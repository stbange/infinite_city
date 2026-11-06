# Proposal: add-streets-and-lanes

## Why

The city feels too loose: blocks fill only 55–85% of their 64 m cells at random positions, and
38% of cells are empty, so neighbouring blocks are usually 15–30 m apart and often a whole empty
cell (64 m or more). A dense city of floating blocks should be packed tight — narrow streets
between almost every pair of blocks — with wide major traffic lanes only now and then, which are
easy to read as the city's avenues and flight levels.

## What Changes

- **Narrow streets:** every block face sits 2–6 m back from its cell face (vertically 0 or 4 m
  at the bottom, 4 or 8 m at the top, on the 4 m floor grid), so neighbouring blocks are 4–12 m
  apart.
- **Major traffic lanes:** on each axis about one in six cell boundaries, chosen per boundary
  from the seed alone, is a lane: blocks on both sides keep 16–18 m (vertically 16 m) back, so the
  lane is a 32–36 m wide plane of open space running straight through the whole city — avenues
  along x and z (also open up and down) and flight levels between layers.
- **Fewer empty cells:** 90% of uncarved cells hold a block (was 62%), the roof layer 96%.
- Shafts, canyons and plazas stay as the rare, much larger voids.

Out of scope (later changes):
- Flying traffic in the lanes → `add-flying-traffic`.
- Bridges across lanes being rarer or special (long-span bridges) → `add-city-connections`.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `city-layout`: block geometry (setbacks instead of random fill), new major traffic lanes, block
  density, roof density and the floor count range.

## Impact

- `CityConfig`: `block_fill_min`, `block_fill_max`, `min_street_gap` are replaced by
  `street_setback_min/max`, `lane_chance`, `lane_setback`, `lane_setback_jitter`; densities change.
- `CityLayout.block_at()` and a new `CityLayout.is_lane(axis, boundary)`.
- The generated city changes for every seed (statistical specs stay valid); screenshots are
  re-rendered. Bridges, doorways, interiors and lighting are unchanged in their rules.
