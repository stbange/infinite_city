# Proposal: add-gang-turf

## Why

M6 of the Fogline plan (dangers): the city pushes back. Gangs hold bridges — the choke points of a
city without ground — and a courier carrying cargo across their turf has to pay, talk or run.

## What Changes

- **Turf:** a bridge is claimed by the gang that owns its district today, or by a gang of the
  Reach whose home district is next to it (some of those bridges); deterministic per seed.
- **Heat:** how wanted the courier is per gang; it rises when they run or fail to pay and halves
  every two game hours.
- **Encounters:** stepping onto a claimed bridge with cargo rolls once per bridge and game hour:
  pass, toll or shakedown (twice the toll), likelier with heat. The courier pays, talks (a chance
  that shrinks with heat; failing turns it into a shakedown) or runs; leaving the bridge counts as
  running. A chase sends the gang's figures after the courier: getting 40 m away (or holding out
  30 seconds) escapes with the cargo and more heat; being caught loses the cargo and credits.
- **HUD:** the bridge's gang when standing on a claimed bridge; the offer with its choices (keys
  1, 2, 3) or the chase distance.

## Capabilities

### New Capabilities
- `gang-turf`: bridge claims, tolls and heat.
- `encounters`: tolls, shakedowns, talking, chases.

## Impact

- New `src/core/turf_map.gd`, `heat.gd`, `encounter_rules.gd`, `src/world/encounter_director.gd`;
  `JobManager.lose_cargo()`; HUD lines; main scene; tests `test/unit/test_gang_turf.gd`,
  `test/integration/test_encounters.gd`.
