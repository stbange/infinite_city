# Design: add-hud-panels

- `MessageQueue.push(source, text, now)` records a source's message only when it changed and is not
  empty; `lines(now)` drops messages older than `DURATION` and returns the newest `MAX_LINES`.
- The HUD polls `last_message` of the session, tools, shop and hazards and the encounter
  director's `last_outcome` on each refresh. `Hud.text()` joins all panels so existing checks hold.
