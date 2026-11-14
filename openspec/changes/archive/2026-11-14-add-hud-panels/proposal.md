# Proposal: add-hud-panels

## Why

M12: the read-out was one long string built from seven systems, and every message stayed until its
source cleared it. Lines piled up at the top left.

## What Changes

- **Panels:** the place (time, location, turf, prices, movement) stays top left; the courier panel
  (wallet, waypoint, gang on the bridge, story objective, guide, stats) sits top right.
- **Messages:** saves, tools, the shop, rescues and gang outcomes share one queue at the bottom
  centre; each new message shows for six seconds, at most four at a time.

## Capabilities

### New Capabilities
- `hud-panels`: read-out panels and the message queue.

## Impact

- New `src/core/message_queue.gd`; `Hud` with three labels and `courier_text()`,
  `messages_text()`; tests.
