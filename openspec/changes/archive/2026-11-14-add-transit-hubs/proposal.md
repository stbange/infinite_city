# Proposal: add-transit-hubs

## Why

M16 of the plan (draft 2): later deliveries are too far to walk. Every district already has a
transit-hub block; it should take the courier somewhere.

## What Changes

- **Hubs:** each district's transit-hub block has a platform door (its first unit on floor 0).
  E there offers rides to the hubs of the four neighbouring districts, the rows above and below,
  and — from every fourth row — express hubs four rows away.
- **Fares:** ¤8 a ride, express two and a half times that; a transit pass from the shop (¤250)
  makes rides free. A ride takes four game minutes and puts the courier in front of the
  destination's platform door.

## Capabilities

### New Capabilities
- `transit`: transit hubs and lifts.

## Impact

- New `src/core/transit_network.gd`, `src/world/transit_director.gd`; shop entry; economy section
  `transit`; main scene with its own panel; tests.
