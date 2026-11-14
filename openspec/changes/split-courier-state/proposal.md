# Proposal: split-courier-state

## Why

M12 of the plan (draft 2): `JobManager` had grown to hold orders, deliveries, the wallet,
standing, the licence and tools, plus the start search and the waypoint. Every new feature touched it.

## What Changes

- **Courier state:** wallet, reputation, licence and tools, with buying, upgrading and using tools,
  move to `CourierState`, saved as its own session part `courier_state`.
- `JobManager` keeps orders and deliveries; the start search (`CourierStart`), door positions
  (`DoorPlaces`), the waypoint (`CourierWaypoint`) and cargo heat (`CargoKind.total_heat`) move out.
- **Saves version 3:** version 2 saves, which kept the courier's state in the courier part, load
  into the new layout unchanged.

## Capabilities

### New Capabilities
- `courier-state`: what the courier owns and is.

### Modified Capabilities
- `save-games`: version 3 with the courier state as its own part.

## Impact

- New `src/core/courier_state.gd`, `src/world/courier_start.gd`, `door_places.gd`,
  `courier_waypoint.gd`; callers use `jobs.courier`; `GameSession.SAVE_VERSION` 3.
