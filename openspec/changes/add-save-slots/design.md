# Design: add-save-slots

- Slots are the JSON files in `user://saves/`; listing reads each file's `saved_at` (UTC date and
  time) and `label` (the game clock) and sorts newest first.
