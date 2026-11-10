# Proposal: add-traversal-tools

## Why

M8, second part: the tools bought in the shop change how the courier moves through a city without
ground — reaching ledges, crossing gaps, finding doors in the fog and shaking off gangs.

## What Changes

- **Grapple (G):** pulls the courier onto a surface they aim at within 20 m.
- **Glider (hold Space while falling):** caps the fall at 3 m/s and carries the courier forward.
- **Scanner (R):** a beacon at the next door, visible through fog and walls for ten seconds,
  within 200 m.
- **Flare (X):** ends a chase at once; one flare is used up.

## Capabilities

### New Capabilities
- `traversal-tools`: grapple, glider, scanner and flares.

## Impact

- New `src/world/traversal_tools.gd`; `WalkModel.step(..., glide)`; `Player.gliding`; main scene;
  tests `test/integration/test_traversal_tools.gd`, glider rule in `test/unit/test_walk_model.gd`.
