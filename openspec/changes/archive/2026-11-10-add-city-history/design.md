# Design: add-city-history

## Decisions

### D1 — Ids and caching
Factions have string keys: `G<n>` for city-wide powers, `R<x>,<y>,<z>#<n>` for local factions of
Reach (x, y, z). `CityChronicle(config)` owns the `CityHistory` and an LRU cache (64) of
`ReachHistory` by Reach coordinate. A Reach is `floor_div(district, 4)`. Districts with a district
row ≥ 1 (above the roof's district) have no history; the roof's district row has one.

### D2 — City history
Era lengths are drawn from `data/eras.json` (min/max years); the Quiet takes 80–130 years and the
others are scaled to fill years 0 to 517 − quiet. Powers: the Authority, 3–5 companies with
distinct goods, 1–2 faiths, one society. Names come from `data/factions.json` patterns filled with
generated family names and word lists (`TextTemplate`). The war antagonist is a company; the era's
name comes from its good. Legends: 2–4 per era with roles from the era table, a birth year so that
they are 16–60 at their event, and a lifespan of 45–95 years.

### D3 — Influence fields
Value noise over district coordinates with a lattice of 8 districts (smoothstep interpolation of
hashed lattice values), times a depth curve per kind: food and water rise with depth, power and
transit peak in the middle, medicine is flat, the Authority falls off as exp(−layers / 120). The
depth uses district layers below the roof's district. Neighbour differences stay below 0.25
because the lattice is 8 wide and the depth curves are gentle.

### D4 — Reach simulation
Seeding (`seed_factions(reach)`, also used for neighbours): 3–5 gangs, 2–3 parties, 1–3 guilds,
0–2 local companies, 0–2 faiths, each with a founding year (gangs and parties mostly in later eras),
a home district, a colour and a start strength. Initial territory at the start of Building Down:
each district goes to the strongest city-wide company or the Authority there (influence field).
Then five-year ticks to 517; at each tick every living faction acts with a chance by type and era:
gangs take districts from weaker owners next to their turf or feud; companies buy districts;
guilds strike against a company; parties win elections or ally; any faction may split (rare) and
collapses below strength 0.08. Collapsed factions are replaced by new ones (up to 24 in total).
War era: raids and blackouts against districts. Border feuds: with a chance per tick, the strongest
gang feuds with a neighbouring Reach's first seeded gang. At the end, missing gang, party or guild
types are founded in the Quiet. Every action records a `HistoryEvent` (year, kind, actor keys,
district, text from `data/events.json`).

### D5 — Territory
Per district a list of `[year, owner key]` claims; `owner_at(district, year)` finds the latest
claim at or before the year. Collapsing owners hand their districts to the strongest neighbouring
claimant or back to the strongest city-wide power.

### D6 — Determinism
All randomness comes from `CellRandom(hash(seed, SALT_*, reach…))` streams; actions iterate factions
in key order. No global state; the cache only stores results of pure functions.
