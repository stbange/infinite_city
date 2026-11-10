# Proposal: add-event-log

## Why

M9 of the Fogline plan: the world remembers. The city is a pure function of the seed; everything
that changes during play — a bridge changing hands, prices, a death, a move — must be stored as
events on top of that baseline, read back by every query, and saved.

## What Changes

- **Event log:** an append-only list of typed events with their game minute (bridge taken, price,
  death, move).
- **Overlays:** the events applied to queries — bridge claims, food prices per district, residents
  of a flat (the dead and the moved-out gone, the moved-in present).
- **Saves v2:** the session saves the event log with the story, reputation, wallet and tools
  (already parts); version 1 saves still load. F5 saves and F9 loads the quick slot.

## Capabilities

### New Capabilities
- `event-log`: the log and its overlays.

### Modified Capabilities
- `save-games`: version 2 with the event log; quick save and load keys.

## Impact

- New `src/core/event_log.gd`, `world_overlays.gd`; `TurfMap.overlays`; `GameSession`
  `SAVE_VERSION` 2, F5/F9; tests `test/unit/test_event_log.gd`, save tests.
