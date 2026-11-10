# Design: add-event-log

- `EventLog`: `events: Array[Dictionary]` of {minute, kind, …}; `append(kind, minute, data)`
  returns the event; `to_dict`/`from_dict` as a plain list.
- `WorldOverlays`: built by applying events in order (`apply(event)`, `rebuild(log)`).
  - `bridge_taken` {bridge: "cell|axis", gang, from} → `claim_override(bridge_key)`.
  - `price` {district: "x,y,z", factor} → `price_factor(district)` (1.0 by default).
  - `death` {person} → `is_dead(key)`.
  - `moved` {person, to: [x, y, z, floor, unit]} → `address_of(key)`; the flat's moved-in list.
  - `residents(population, cell, floor, unit)` = baseline residents minus dead and moved-out plus
    moved-in (looked up by key).
  - `state_hash(population, layout, cells)` hashes claims, prices and residents over cells (tests).
- `TurfMap.claim_of` returns an overlay claim before the baseline.
- `GameSession`: SAVE_VERSION 2 (the event log is a part registered by the simulation runner);
  versions 1 and 2 load; F5/F9 save and load the "quick" slot.
