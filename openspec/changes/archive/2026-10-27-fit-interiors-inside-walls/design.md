# Design: fit-interiors-inside-walls

## Context

`InteriorLayout.floor_of()` builds each floor from boxes. Today `_slab()` covers the block's whole
footprint and `_outer_walls()` builds pieces from a floor's level to 4 m above it. Slab k
(`y_k − 0.3 … y_k`) therefore lies inside the outer walls of floor k − 1 (`y_k − 4 … y_k`); the
slab's side faces coincide with the façade's outer faces. The roof slab does the same with the
top floor's walls. The stair core starts at `x = 1.25`, the core unit's side wall occupies
`1.25 … 1.37`, so steps and landings overlap it. `InteriorView` draws slabs, walls, stairs and
façade with different materials, which makes these overlaps flicker.

## Decisions

### D1 — Slabs cover the inner rectangle
`_slab()` uses `plan.inner` (the block footprint minus the 0.3 m outer walls) instead of the
block footprint; the stair opening is cut from it as before. The same applies to the roof slab.
A slab's side faces then touch the inner faces of the outer walls back to back (facing each other),
which is invisible from both sides.

### D2 — The façade closes the slab band
Outer walls keep running from `y_k` to `y_k + 4`, so walls of consecutive floors meet with no gap
and cover the slab band. Floor 0 has no walls below it, so its outer wall pieces start at
`y_0 − SLAB`; the bottom of the lowest slab and the bottoms of those walls are flush. The coarse
collision shell follows the same rule. Window and entrance openings are unchanged (they start
above the slab).

### D3 — Stair core on the wall's inner face
`plan.core` moves from `x = CORRIDOR_HALF` to `x = CORRIDOR_HALF + UNIT_WALL`, the inner face of
the core unit's west wall. The core is 3.4 m + 0.12 m enclosure wide, and the core unit is at
least 6 m wide (its east boundary is a grid line ≥ 8 m), so the core still fits. The core unit's
door position and the stair opening follow `plan.core`. The hut sits over the core as before.

### D4 — The overlap check
A test collects the drawn boxes of two neighbouring floors, tags each with its material group
(as `InteriorView` draws them: façade, glass, slab, wall, stair, furniture, light) and checks
every pair of different groups: the intersection may not exceed 2 mm along all three axes.
Same-group overlaps are drawn identically and are allowed.

## Risks / Trade-offs

- [Visible change] Moving the stair core and the slab edges changes the interiors a little;
  determinism is unaffected (no new randomness).
- [Test runtime] The pairwise check is O(n²) per floor pair (~1,000 boxes); sorting by x keeps
  it well under a second per pair.
