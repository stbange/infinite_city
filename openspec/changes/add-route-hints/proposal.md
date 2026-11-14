# Proposal: add-route-hints

## Why

M14 of the plan (draft 2): finding the door is the courier's core skill, and it was guesswork —
an arrow and a distance, with corridors, stairs and bridges in between.

## What Changes

- **Route hints:** small lights on the floor along the next 30 m of the walking route to the next
  door (or the patron's counter), replanned when the courier strays more than 3 m; H turns them off.
- **Scanner:** a scan now also lights the whole route for ten seconds.

## Capabilities

### New Capabilities
- `wayfinding`: route hints, gang-aware routes and chases over the navigation graph.

## Impact

- New `src/world/route_hints.gd`; `CityNav.nearest_node`, `route_between`, `NavRoute.cost`
  (walking length kept separate); `TraversalTools.hints_path`; HUD; main scene; tests.
