# Design: add-streets-and-lanes

## Context

`CityLayout.block_at()` draws each block's size per axis as a random fill (55–85%) of the cell and
a random offset within the remaining room, keeping 4 m from every cell face. Occupancy is 62%
below the roof. Everything else (bridges, doorways, interiors, signs) derives from block boxes.

## Decisions

### D1 — Setbacks instead of fill
A block is described by how far each of its six faces sits back from the cell face behind it:
`lo = −half + setback_lo`, `hi = half − setback_hi`. Horizontal street setbacks are uniform in
[2, 6] m, so the gap across a boundary (the sum of the two blocks' setbacks) is 4–12 m. Vertical
setbacks must keep tops and bottoms on the 4 m grid and still guarantee a gap: bottom ∈ {0, 4},
top ∈ {4, 8}, so vertical gaps are 4, 8 or 12 m. Tops never lie on the cell face, so a player
standing on a roof is inside that block's cell (read-out, spawn point). Every face draws its random number whether or
not it faces a lane, so the stream (and the later function pick) does not depend on lanes.

### D2 — Lanes are boundary planes
`is_lane(axis, b) = u01(hash2(seed, SALT_LANE, axis, b)) < lane_chance` for the boundary between
cells b − 1 and b. Because the decision ignores the other two coordinates, a lane is an endless
plane: x- and z-lanes are vertical slots (avenues open up and down), y-lanes are horizontal flight
levels. Across a lane both blocks set back `lane_setback` (16 m) plus up to `lane_setback_jitter`
(2 m) horizontally, or exactly 16 m vertically (a whole number of floors). With probability 0.16 a
lane appears on average every ~6 cells (~380 m), so the city reads as dense superblocks separated
by avenues.

### D3 — Densities and guarantees
Base density 0.9, roof 0.96; sky layers unchanged. The guaranteed core around the cell centre is
`half − (lane_setback + jitter)` = 14 m horizontally and `half − lane_setback` = 16 m vertically,
larger than before (7.2 m), so bridges (6 m wide on the centre line), stair cores and corridor
crosses keep fitting. Blocks are 32–60 m tall (8–15 floors).

### D4 — Config
`block_fill_min`, `block_fill_max` and `min_street_gap` are removed; new exports
`street_setback_min = 2`, `street_setback_max = 6`, `lane_chance = 0.16`, `lane_setback = 16`,
`lane_setback_jitter = 2`. `validate()` checks the ranges and that the core stays positive.

## Risks / Trade-offs

- [More geometry] ~45% more blocks per chunk and larger blocks: more MultiMesh instances and
  larger interiors. Chunk generation stays in the low milliseconds.
- [Whole city changes] Every seed produces a different city; statistical specs hold, screenshots
  and README numbers are refreshed.
- [Doorways in alleys] Magic doorways may now face a 4 m street; they still work, and the
  screenshot tool already looks for one with a clear view.
