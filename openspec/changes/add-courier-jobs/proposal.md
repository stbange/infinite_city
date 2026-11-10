# Proposal: add-courier-jobs

## Why

Slice A of the Fogline plan: the first playable loop. Take a food order at your patron's counter,
find the customer's door in the fog, hand over the food, get paid, pay the rent. Milestone M4.

## What Changes

- **Addresses:** every door has an address — layer, Reach, block name, floor, unit — such as
  "L-19 · Juniper Reach · Copper-217 · Fl 12 · Unit 4"; district names are unique within a Reach.
  Addresses format and parse both ways and resolve to the door. Floor numbers are shown at the
  stairs of entered blocks.
- **Start scenario:** the patron is the nearest active food business to the start; the player's
  home is the nearest vacant flat.
- **Food orders:** every game hour the patron's counter offers three orders from occupied flats
  within two cells, deterministic per patron, day and hour.
- **Jobs:** interacting with the patron's door accepts the next order (up to three carried);
  interacting with the customer's door delivers it. Pay is a base plus distance and floors, plus a
  tip that shrinks as the food cools over 30 game minutes.
- **Wallet and rent:** credits; rent of ¤120 is charged every Monday at 06:00.
- **Waypoint and HUD:** an arrow, distance and floor difference to the next door; the wallet, rent
  and current jobs on the HUD.

Out of scope: walking routes and visible customers (M5), dangers (M6), story jobs (M7).

## Capabilities

### New Capabilities
- `addresses`: place names, addresses and floor signs.
- `courier-jobs`: start scenario, orders, jobs, pay, wallet, rent, waypoint and HUD.

### Modified Capabilities
(none)

## Impact

New core: `place_names.gd`, `address.gd`, `start_scenario.gd`, `delivery_job.gd`,
`courier_board.gd`, `wallet.gd`. New scene: `src/world/job_manager.gd`. Changed: `Interaction`
(label hooks), `InteriorView` (floor signs), `Hud`, `GameSession` (saves wallet and jobs),
`main.tscn`.
