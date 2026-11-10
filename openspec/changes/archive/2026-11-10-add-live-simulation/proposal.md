# Proposal: add-live-simulation

## Why

M9, second part: the world moves on. In the districts the courier knows, gangs take bridges,
prices follow the blight, and people die and move — written to the event log, so it stays true
after quitting and reloading.

## What Changes

- **Live area:** the start district and every district the courier has walked in.
- **Daily ticks:** once per game day for each live district, deterministic per seed, day and the
  log so far: a gang may take a bridge in the district; the food price drifts (and climbs toward
  three times once the story's shortage has begun); a resident may die or move to a vacant flat.
  Cast characters of the story never die or move by chance.
- **Effects:** gangs hold the bridges they took; order pay follows the district's food price;
  dead customers stop ordering; the HUD shows the food price where it is not normal.

## Capabilities

### New Capabilities
- `live-simulation`: the live area and its daily ticks.

## Impact

- New `src/core/live_simulation.gd`, `src/world/simulation_runner.gd`; pay and customers read the
  overlays; HUD price line; main scene; tests `test/unit/test_live_simulation.gd`,
  `test/integration/test_simulation_runner.gd`.
