# Proposal: fit-interiors-inside-walls

## Why

Entered blocks flicker. Floor slabs and the roof slab span the whole block, so their edges sit
inside the outer walls of the floor below, and two different materials (façade and floor) share
the same outer surface in a band at every floor line. The stair core starts exactly on the
stairwell's side wall, so steps and landings share faces with that wall too. Wherever two
materials occupy the same surface the depth test cannot decide between them and the pixels
fight (z-fighting).

## What Changes

- **Floors inside the outer walls:** floor slabs and the roof slab cover only the space inside
  the outer walls; the outer walls run from floor level to floor level without interruption, and
  the lowest floor's walls reach down to the bottom of its slab, so the façade is one closed
  surface.
- **Stairs inside the stairwell walls:** the stair core starts on the inner face of its unit's
  side wall instead of on the wall's centre line.
- **No overlapping surfaces:** an automated check makes sure no two drawn boxes of different
  materials overlap anywhere in a floor or between neighbouring floors.

Out of scope (later changes):
- Overlaps between boxes of the same material (for example inner walls meeting at corners) are
  invisible, because both surfaces are drawn identically, and stay as they are.
- Lifts, doors and the rest of the `add-block-interiors` follow-ups.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `block-interiors`: floors lie inside the outer walls, the stair core sits inside its walls,
  and drawn surfaces of different materials never overlap.

## Impact

- `src/core/interior_layout.gd` (`plan_of()` stair core position, `_slab()`, `_outer_walls()`),
  `src/core/interior_plan.gd` unchanged in shape.
- Tests: `test/unit/test_interior_floor.gd` gains the overlap and fit scenarios.
- Interiors change slightly (stair core 12 cm further east); generation stays deterministic.
