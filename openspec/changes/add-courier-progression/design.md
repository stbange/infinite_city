# Design: add-courier-progression

- `Reputation`: `points[key]`, `add(key, n)` clamped to ±100, `level(key)` by thresholds −50, −10,
  25, 75. Key "mutual" is the Couriers' Mutual. Delivery +1 (story delivery +3); toll paid +2 with
  the gang; run −10; caught −5.
- `Licence`: levels bronze, silver, gold; `max_tier(level)` 1, 2, 3; `next_requirements(level)` →
  {mutual, fee}; `can_upgrade(level, reputation, credits)`.
- `CargoKind.TABLE`: kind → {tier, pay (multiplier), heat (encounter heat added while carried),
  label}. `CourierBoard.offers(patron, day, hour, max_tier)`: the order list is unchanged; for
  max_tier ≥ 2 each order becomes higher-tier cargo when `hash(seed, SALT_CARGO, patron, day, hour,
  i)` < 0.35, its tier drawn up to max_tier; base pay × multiplier.
- `ShopCatalogue.TOOLS`: scanner ¤60 bronze, flare ¤20 bronze (consumable), glider ¤180 silver,
  grapple ¤240 silver. `can_buy(tool, licence, credits, owned)`.
- `EncounterDirector`: trusted → pass; friendly → toll × 0.7; carried cargo heat is added to the
  roll's heat.
- `CourierShop` (world): U toggles the shop in its own `DialoguePanel`; choices list tools and the
  licence upgrade; buying updates `JobManager.tools`, `licence` and the wallet.
