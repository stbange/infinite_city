# Proposal: add-residents

## Why

Every Fogline delivery ends at a door with a person behind it, and every job comes from a real
workplace. Milestone M2 of the Fogline plan: give every flat a household and every workplace a
staff, consistent from both sides, generated lazily from the seed like the rest of the city.

## What Changes

- **Households:** every flat (non-core unit of a housing block) gets a household fitting its size —
  vacant, single, couple, family or flatmates, up to six people — with a shared family name from
  a naming culture that depends on where in the city it is.
- **Persons:** age, pronouns, three personality traits, a skill, wealth, health, and possibly a
  (sometimes secret) membership in a faction of their Reach.
- **Workplaces:** every non-core unit of every other block is a workplace of the block's function
  with a business name, opening hours and job slots scaled so that a district's slots cover about
  90% of its working-age adults.
- **Job market:** per district, every working-age adult (18–67) is assigned a workplace by a
  deterministic weighted draw; a workplace's staff is the reverse lookup. Computed in under 1.5 s,
  prefetched on a worker thread, cached.
- **Door plates and read-out:** door plates near the player name the household or business;
  interacting with a door shows who lives or works there.

Out of scope: relations (M3), routines and visible people (M5).

## Capabilities

### New Capabilities
- `residents`: households, persons, names, door plates and the residents card.
- `workplaces`: workplaces, job slots and the job market.

### Modified Capabilities
(none)

## Impact

New: `src/core/person_id.gd`, `person_info.gd`, `household.gd`, `population.gd`,
`workplace_info.gd`, `job_market.gd`, `data/workplaces.json`, `data/traits.json`. Changed:
`CityWorld` (owns the population), `InteriorManager` and `InteriorView` (labels, door plates),
`Hud` (residents card).
