# Proposal: add-save-slots

## Why

M18: one quick slot is not enough for a game people keep.

## What Changes

- **Named slots:** the menu saves into a new slot named after the date and time and lists the six
  newest slots to load, each with the game time it was saved at.
- **Autosave:** E at the courier's own door sleeps until 07:00, recharges the lamp and saves into
  the "autosave" slot.

## Capabilities

### Modified Capabilities
- `release-candidate`: save slots and sleeping.

## Impact

- `GameSession.list_slots`, `new_slot_name`, `saved_at` and `label` in saves; new
  `src/world/home_rest.gd`; `GameMenu` slots; HUD; main scene; tests.
