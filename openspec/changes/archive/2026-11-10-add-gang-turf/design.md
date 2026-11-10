# Design: add-gang-turf

- `TurfMap(chronicle, layout)`: `claim_of(bridge)` — the present owner of the district of the
  bridge's first cell if it is a gang; otherwise each living gang of that Reach whose home district
  is within one district claims it when `u01(hash(seed, SALT_TURF, cell_a, axis, gang index)) <
  NEIGHBOUR_CLAIM (0.3)`; first match wins. Cached per bridge.
- `Heat`: per gang key a value and the minute it was set; `value_at(key, minute) = v · 0.5^(Δ/120)`;
  `add(key, amount, minute)`; saved as a dictionary.
- `EncounterRules`: `toll(cargo, heat) = round((8 + 4·cargo) · (1 + heat))`;
  `roll(seed, bridge, hour, cargo, heat)` → "pass" without cargo, else from `hash(seed, SALT_ENCOUNTER,
  cell_a, axis, hour)`: shakedown below 0.15 + 0.25·min(heat, 1), toll below that + 0.55, pass
  otherwise; `talk_succeeds(...)` below 0.5 − 0.3·min(heat, 1) with its own salt.
- `EncounterDirector` (world): finds the claimed bridge under the walking player (on the deck
  between its ends, within its width, near its height); states idle → offer → idle or chase. The
  offer spawns three gang figures (PersonAgent, activity "gang") on the deck ahead; a chase moves
  them toward the player at 6 m/s (the player sprints faster); caught within 1.5 m, escaped beyond
  40 m or after 30 s. Each bridge rolls once per game hour. Heat and the resolved set are saved in
  the session part "encounters".
