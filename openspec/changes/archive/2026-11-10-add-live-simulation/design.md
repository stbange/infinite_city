# Design: add-live-simulation

- `LiveSimulation.tick(population, chronicle, overlays, day, districts, shortage, protected)` →
  events (not yet applied). Per district, from `hash(seed, SALT_LIVE, district, day, n)`:
  - takeover (chance 0.35): a gang (the district's owner if a gang and the gangs living within one
    district; any living gang of the Reach when there are none) tries up to four random cells of the
    district; the first bridge not already its own becomes its (`bridge_taken`).
  - price: `factor' = clamp(factor · (1 + (u − 0.5) · 0.1), 0.8, 1.5)`, or halfway to 3.0 with the
    shortage; recorded when it changes by at least 0.01.
  - life (chance 0.3): a random resident of a random housing cell of the district (not protected,
    not dead, not moved) dies (likelier when old) or moves to the first vacant flat of a nearby
    housing block.
- `SimulationRunner` (world): the log and overlays; visited districts (player's district each
  frame); runs the ticks for every day since the last tick (at most 7 at once); feeds the overlays
  to the encounter turf and the job manager; saves {log, visited, ticked} as the part "events".
- `JobManager.open_orders` multiplies base pay by the drop-off district's price factor and skips
  dead customers.
