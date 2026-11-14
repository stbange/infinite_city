# Proposal: add-lifts-and-spans

## Why

M16: tall blocks take minutes of stairs. Lifts in their stair cores make floors far apart close.

## What Changes

- **Lifts:** blocks of twelve floors or more (roughly a quarter to a third of blocks) have a lift in the stair core: E at the landing offers the
  ground floor, the top floor and five floors up or down; routes use the lift too.
- **Long spans** across canyons are not part of this change: they need openings in block walls
  and new bridge geometry, which would rewrite the city's bridge layout. They move to the roadmap.

## Capabilities

### Modified Capabilities
- `transit`: lifts.

## Impact

- `BlockNav` lift edges and `has_lift`; `TransitDirector` lift targets and rides; tests.
