# Design: add-courier-jobs

- `PlaceNames(chronicle-free, seed)`: district names from `data/factions.json` reach words shuffled
  per Reach (64 districts, 100 words, a permutation slice → unique per Reach); block number =
  local index x·64 + y·8 + z + 1; layer label `L<y − roof>`.
- `Address`: `format(layout, names, cell, floor, unit)`; `parse(text)` → layer, Reach, district
  name, block number, floor, unit; `resolve_near(text, layout, names, near_cell)` searches the Reaches
  around `near_cell` for the named Reach and district at that layer.
- `StartScenario.find(population, cell)` scans cells within 3 / 2 for market blocks whose units are
  active food workplaces in their district's job market, nearest first; home = nearest vacant flat
  in housing blocks within 4 cells.
- `CourierBoard.offers(patron, day, hour)` draws from `hash(seed, SALT_ORDERS, patron unit, day·24 +
  hour)`: three tries per order for a random cell within ±2 / ±1, a flat, an occupied household,
  an adult. `DeliveryJob` stores the pickup unit, drop-off unit, customer, created/picked minute,
  base pay. `Wallet`: credits, rent schedule.
- `JobManager` (scene): registers a label hook on `Interaction` and listens to `interacted`;
  accepts, delivers, charges rent on the session clock, saves into the session's dict under
  "courier", and exposes `waypoint()` (scene position of the next door) for the HUD.
- `InteriorView` floor signs: Label3D "Fl n" beside the stair core's front landing for the plate
  floors.
