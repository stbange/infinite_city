# Design: add-economy-tables

- Former constants (`CourierBoard.BASE`, `Wallet.RENT`, `EncounterRules.GANG_SPEED`, …) become
  static properties whose getter calls `Economy.num(section, key)`, so names and call sites stay.
  `Economy.set_override` / `clear_overrides` change single values.
- `BalanceSim.play(patron, start, end, speed, max_tier)`: each game hour takes up to three open
  orders, walks counter → doors → counter over `CityNav` routes (straight line × 1.6 when a route
  is too far to search) at 4.5 m/s plus 25 m per door, and pays with the cooling rule.
- Tuning target (checked by a test): half a game day of steady play earns between a fifth and a
  half of the weekly rent, and some food still arrives hot.
- `PlayStats` counts in game minutes; `SessionCoach` feeds it from `JobManager.delivered`,
  `EncounterDirector.paid` and `HazardDirector.rescued`; F4 toggles its lines on the HUD.
