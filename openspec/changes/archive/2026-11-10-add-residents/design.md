# Design: add-residents

## Decisions

### D1 — Ids
`PersonId` = district + a local int packing the cell's position in its district (3 × 3 bits), the
floor (5 bits), the unit index (7 bits) and the household slot (3 bits). Workplaces are keyed the
same way with slot 0. Dictionary keys within a district are local ints; across districts
`PersonId.key()` strings.

### D2 — Households (cheap)
`Population.household(cell, floor, unit)` draws from `hash(seed, SALT_HOUSEHOLD, cell, floor·128 +
unit)`: vacancy 8%, then the type by flat area (under 90 m²: single 55%, couple 35%, flatmates
10%; larger: couple, family, flatmates, single), members' ages (families: two adults 26–55 or one
parent, children 0–17 at least 16 years younger, sometimes an elder 68–90). Only ages are needed
for the job market; full `PersonInfo` is built on demand. Plans are cached per block.

### D3 — Persons
`Population.person(id)`: given name by culture, the household's family name (flatmates get their
own), pronouns 47/47/6, three traits (three of five axes in `data/traits.json`, low or high),
a skill (hands, numbers, care, words, tech), wealth from depth and district plus noise, health,
membership with chance 0.22 among the Reach's factions alive at 517 (the district's gang owner
weighted ×3). The culture of a district comes from a hash of its Reach and its depth band.

### D4 — Job market
For a district: collect workplaces (units × floors of non-housing blocks; raw slots = area /
m² per worker from `data/workplaces.json`), collect working-age adults (households of all housing
blocks), scale slots to 90% of adults with deterministic rounding (`floor(raw · scale + u01)`), then
for each adult in block/floor/unit/slot order draw a workplace from the cumulative slot array
(retrying up to 8 times, accepting with the skill's affinity for the kind, then probing for the
next workplace with a free slot). Stored both ways. ~0.5 s per district in GDScript.

### D5 — World
`CityWorld.population` (with `InteriorLayout`, the chronicle and a job-market cache of 6) and a
`BackgroundJobs` prefetch of the player's district. `InteriorManager.door_targets()` labels doors
through the population; `InteriorView` shows door plates (Label3D) on the player's floor ± 1. The
HUD listens to `Interaction.interacted` and shows a residents card for 6 seconds.
