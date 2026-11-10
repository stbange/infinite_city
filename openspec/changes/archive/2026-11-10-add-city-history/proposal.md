# Proposal: add-city-history

## Why

Fogline's factions, residents and story need a past: who built the city, who sealed the roof,
which gangs, companies, guilds, parties and faiths fought over each part of it, and who owns each
district today. Milestone M1 of the Fogline plan, part 1 (the pure history; the visible traces
follow in `add-faction-traces`).

## What Changes

- **City history (one per seed):** six eras in a fixed order — the Raising, Building Down, the
  Sealing, the Doorway Rush, a war era, the Quiet — with generated names, lengths and outcomes,
  covering years 0 to 517; 6–10 city-wide powers (one Authority, companies for distinct vital goods,
  faiths, a secret society); 10–20 legends tied to era events.
- **Influence fields:** each city-wide power has a smooth strength at every district, with a depth
  preference (food and water companies deep, the Authority near the roof).
- **Reach history:** for every Reach (4 × 4 × 4 districts) a faction simulation in five-year steps:
  8–16 local factions (gangs, parties, guilds, local companies, faiths) are founded, ally, feud,
  take districts, strike, split and collapse; every event has a year, actors, a place and a text.
- **Territory:** every district of the city below the sky has exactly one owner at any year.
- **Neighbours:** border feuds reference the neighbouring Reach's first gang, computed without that
  Reach's own history, so histories stay local.
- Data tables `data/eras.json`, `data/factions.json`, `data/events.json`.

Out of scope: signs, tags, memorials, ruins and the HUD (→ `add-faction-traces`); residents and
their memberships (M2); faction actions during play (M9).

## Capabilities

### New Capabilities
- `city-history`: eras, city-wide powers, legends, influence, Reach histories and territory.

### Modified Capabilities
(none)

## Impact

New pure classes in `src/core/`: `CityChronicle`, `CityHistory`, `EraInfo`, `FactionInfo`,
`LegendInfo`, `HistoryEvent`, `InfluenceField`, `ReachHistory`, `Territory`; `DataTables` gets the
three schemas. No scene changes.
