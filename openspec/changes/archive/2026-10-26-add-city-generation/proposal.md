# Proposal: add-city-generation

## Why

The whole game takes place in a city that has no end except its roof. Before anything can be
rendered, streamed or walked through, we need a generator that can answer "what is at this
place?" for any coordinate — far below, far to the side, at the roof — instantly, without
generating the rest of the city first, and identically every time. This is the foundation
every later change builds on.

## What Changes

- Introduce a deterministic, integer-coordinate world model: the city is a 3D lattice of
  **cells**; a cell either holds one floating **block** or is open air.
- The city has exactly one border, the **roof layer**. A few sparse **sky layers** of floating
  blocks sit above it; above those nothing is ever generated. Downward and horizontally the
  city is unbounded.
- **Canyons** carve the lattice into navigable open space: vertical **shafts** that run
  without end from the sky down, horizontal **canyons** that run without end along the X and
  Z axes, and local **plazas**.
- Every block gets a **function** (housing, farms, markets, offices, industry, parks) whose
  mix depends on depth, and every **district** (8×8×8 cells) is guaranteed one of each
  **essential service**: hospital, fire station, security station, school, power plant,
  water works and transit hub.
- Every block gets a deterministic size and offset inside its cell, always leaving a
  street gap to its neighbours.
- **Bridges** connect some horizontally adjacent blocks.
- Cells are grouped into **chunks** (4×4×4 cells) that can be generated independently.

Out of scope (later changes):
- Loading/unloading chunks around the player, floating origin and rendering → `add-world-streaming`.
- Doorways into bigger-on-the-inside spaces → `add-pocket-doorways`.
- Teleport network between transit hubs, long-span bridges across canyons, vertical
  connections (lifts), flying traffic lanes, block interiors → later proposals.

## Capabilities

### New Capabilities
- `city-layout`: the shape of the city — cell lattice, roof and sky boundary, occupancy,
  canyons, block geometry, determinism and chunk generation.
- `city-zoning`: what each block is used for — block functions, the depth-dependent mix and
  the per-district essential-service guarantee.
- `city-bridges`: pedestrian bridges between neighbouring blocks.

### Modified Capabilities
- None (first change).

## Impact

- New pure-logic code under `src/core/` (`DetHash`, `CellRandom`, `CityConfig`, `BlockTypes`,
  `BlockInfo`, `BridgeInfo`, `ChunkData`, `CityLayout`, `IntMath`).
- New unit tests under `test/unit/`.
- No scene or rendering changes yet; no new dependencies.
