# Proposal: add-escorts

## Why

M15: cargo tier 4 from the concept — people. A witness or a runaway travels with the courier.

## What Changes

- **Escort jobs:** with a gold licence some orders are a person (tier 4, best pay).
- **Following:** the passenger appears with the courier and follows over the navigation graph at
  3.6 m/s (slower than a sprint); while a gang chases, they freeze.
- **Arriving together:** the delivery only counts with the passenger within 6 m of the door.

## Capabilities

### New Capabilities
- `escorts`: people as cargo.

## Impact

- `CargoKind` "person"; `Licence.max_tier("gold")` = 4; new `src/world/escort.gd`;
  `JobManager.escort_path`, `last_message`; economy section `escorts`.
