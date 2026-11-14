# Proposal: add-gang-aware-routes

## Why

M14: "pay the toll or take the long way" should be a visible choice, and gangs should chase the
courier through the stair cores instead of through walls.

## What Changes

- **Gang-aware routes:** with J, route hints avoid bridges held by gangs (a 300 m penalty each), so
  the lights show the detour when there is one.
- **Chases on the graph:** chasers plan paths over the navigation graph to the courier twice a
  second and follow them; the last stretch is straight.

## Capabilities

### Modified Capabilities
- `wayfinding`: gang-aware routes and chases.

## Impact

- `CityNav.bridge_penalties`; `RouteHints.avoid_gangs`; `EncounterDirector.chase_paths`; tests.
