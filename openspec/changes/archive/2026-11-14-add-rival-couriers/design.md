# Design: add-rival-couriers

- `rival_minute(patron, day, hour, index)` from `hash(seed, SALT_RIVAL, patron, hour index, order)`:
  −1 above `rival_share`, else 10 + (h >> 12) mod 50. Deterministic, so saves and replays agree.
