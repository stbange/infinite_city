# Proposal: add-blackouts

## Why

M15: the concept's blackouts — districts going dark deep down — and the courier's lamp.

## What Changes

- **Blackouts:** a live-simulation event; a district's windows go dark from 19:00 of the day to
  06:00, saved in the event log; the HUD says so.
- **Lamp (L):** a light on the courier's view with a battery that lasts ten game hours and
  recharges at the patron's counter.

## Capabilities

### New Capabilities
- `blackouts`: blackout events, dark windows and the lamp.

## Impact

- `LiveSimulation` blackout draw; `WorldOverlays.blackouts`, `is_dark`; block shader blackout flag;
  `ChunkView.set_blackout`; `SimulationRunner.dark_districts`; new `src/world/courier_lamp.gd`; HUD.
