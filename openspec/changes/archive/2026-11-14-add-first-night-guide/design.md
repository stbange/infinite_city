# Design: add-first-night-guide

- `FirstNightGuide.STEPS` in order: order_taken, delivered, scene_answered, shop_opened;
  `prompt(patron)` gives the first unfinished step; saved as the session part "guide".
- `SessionCoach` marks steps: more ordinary orders carried than before, `JobManager.delivered`,
  `DialoguePanel.chosen`, `CourierShop.was_opened`.
