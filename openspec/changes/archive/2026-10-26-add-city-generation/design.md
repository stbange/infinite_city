# Design: add-city-generation

## Context

Empty Godot 4.7 project (see proposal.md — Why). Requirements are in the three spec deltas.
All logic in this change is pure GDScript under `src/core/`, tested headless with GUT.

## Goals / Non-Goals

**Goals:**
- Answer "what is in cell (x, y, z)?" in O(1) without generating neighbours first.
- Bit-identical results on every platform and Godot 4.x version.
- Cheap enough to generate a 64-cell chunk in a few milliseconds of GDScript.

**Non-Goals:**
- Rendering, streaming, threading (next change).
- Smooth noise or curved canyons — the canyon network is deliberately axis-aligned so the city
  reads as a constructed megastructure, and so it can be defined with integers only.

## Decisions

### D1 — Own integer hash instead of engine hashing or noise
`DetHash` (`src/core/det_hash.gd`) implements MurmurHash3 x86_32 over 32-bit words. Godot's
`hash()` and `FastNoiseLite` are not documented as stable across engine versions, and
`FastNoiseLite` takes float coordinates that lose precision far from the origin.
GDScript `int` is 64-bit signed; a 32 × 32-bit product can overflow it, so multiplication is
done by `_mul32()` which splits one factor into 16-bit halves (all intermediates < 2^49).
Negative coordinates enter the hash as their two's-complement low 32 bits.
Golden values are cross-checked against an independent Python reference implementation.

*Alternative considered:* `RandomNumberGenerator` seeded per cell. Rejected as the single source
of truth because its algorithm is an engine implementation detail; we still avoid it inside
generation entirely.

### D2 — Per-cell random stream
`CellRandom` (`src/core/cell_random.gd`) is a 32-bit PCG (RXS-M-XS) seeded from one `DetHash`
value. A cell needs ~8 random draws (size, offset, function); one hash + cheap PCG steps is ~5×
faster than hashing per draw.

### D3 — Coordinates relative to the roof
`CityConfig.roof_layer` (R) can move the roof. Internally everything uses `y_rel = y - R`.
District coordinates: `dx = floor(x / 8)`, `dz = floor(z / 8)`, `dy = floor((y_rel - 1) / 8)`,
so the roof (y_rel = 0) is the top layer of district row dy = -1 and the sky layers fall into
row dy = 0. `IntMath.floor_div()` implements floored division for negatives
(GDScript `/` truncates toward zero).

### D4 — Canyon network defined per district line
- **Shaft** in column (dx, dz): exists if `u(seed, SALT_SHAFT, dx, dz) < shaft_chance`; width
  2–3 cells and position inside the district come from the same hash stream. Depends only on
  (dx, dz) → automatically continuous over all y.
- **X canyon** in row (dy, dz), **Z canyon** in row (dx, dy): exist if the row's hash is below
  `canyon_chance` and dy ≤ -1. Cross-section width 2–3, height 1–2 cells. Depends only on the
  row → continuous over the whole axis.
- **Plaza** in district (dx, dy, dz), dy ≤ -1: box of 1–3 cells per axis.
Each descriptor is cached in a bounded dictionary (cleared when it exceeds 4096 entries), so a
chunk query costs a handful of hashes per district rather than per cell.

### D5 — Occupancy
`is_solid(cell)`: false above R + S; false if carved; else `u(seed, SALT_OCCUPANCY, x, y, z) <
density(y_rel)`, where density is `roof_density` at the roof, `base_density` below, and
`sky_density × (S - k + 1) / S` on sky layer k.

### D6 — Zoning by district plan
Essential services are placed per district by `CityLayout._district_plan()`: for each of the 7
services in a fixed order, draw up to 64 random cells from a `CellRandom` seeded by
`(seed, SALT_SERVICES, dx, dy, dz)` and take the first solid, unassigned one. If all attempts
fail (very sparse districts), scan the district in x→y→z order. Every other block draws its
function from a weighted table chosen by depth band (sky / 0–23 / 24–95 / 96+), so services
appear nowhere else. Tables live in `BlockTypes` (`src/core/block_types.gd`).

### D7 — Block geometry stored relative to the cell centre
`BlockInfo.size` and `BlockInfo.offset` are `Vector3` in metres relative to the cell centre.
Absolute float positions are never stored: `Vector3` is 32-bit, so absolute positions millions
of metres away would be quantised to metres. Renderers combine the integer cell with the
local offset relative to a floating origin (next change).
Size per axis = `cell × fill`, fill ∈ [0.55, 0.85], clamped to `cell - min_street_gap`.
Offset per axis ∈ ±((cell - size - min_street_gap) / 2), which keeps 4 m clearance and
guarantees the centre is inside the box.

### D8 — Bridges keyed by lower cell
`bridge_between(a, axis)` with `b = a + axis` (axis X or Z) exists if both are solid and
`u(seed, SALT_BRIDGE, a, axis) < bridge_chance`. The deck centre line is chosen inside the
overlap of both blocks' lateral and vertical extents (which always overlap by ≥ 14 m around the
cell centre line by D7). Endpoints are expressed relative to cell `a`'s centre. A chunk owns the
bridges whose `a` cell it contains; `bridges_of(cell)` checks the four horizontal neighbours.

### D9 — Files
| File | Purpose |
|---|---|
| `src/core/int_math.gd` (`IntMath`) | floored division / modulo for negative ints |
| `src/core/det_hash.gd` (`DetHash`) | MurmurHash3 32-bit, `u01` helpers |
| `src/core/cell_random.gd` (`CellRandom`) | PCG32 stream |
| `src/core/city_config.gd` (`CityConfig`, Resource) | all tunables + `validate()` |
| `src/core/block_types.gd` (`BlockTypes`) | function enum, names, colours, weight tables |
| `src/core/block_info.gd` (`BlockInfo`) | cell, function, size, offset |
| `src/core/bridge_info.gd` (`BridgeInfo`) | cells, axis, start, end, width, deck height |
| `src/core/chunk_data.gd` (`ChunkData`) | blocks + bridges of one chunk |
| `src/core/city_layout.gd` (`CityLayout`) | the generator (queries + chunk generation) |

## Risks / Trade-offs

- [GDScript speed] Hashing in script is ~µs per call → measured in a test-side benchmark;
  mitigated by district-level caching and one hash per cell. If still too slow, port
  `DetHash`/`CityLayout` to C++ GDExtension behind the same API (tests stay unchanged).
- [Cache growth] Unbounded dictionaries in long sessions → bounded caches that reset.
- [Thread safety] Caches are not thread-safe → generation runs on the main thread for now;
  threaded generation will need per-thread `CityLayout` instances (cheap: config is shared,
  caches are per instance).
- [Float precision] Only local offsets are floats (D7); integer coordinates cover the full
  32-bit range. `cell_bounds()` returns absolute floats and is meant for tests/small coordinates.
- [Statistical tests] Scenario thresholds are statistical but the generator is deterministic, so
  tests never flake; they can only break when generation changes, which is what they guard.
