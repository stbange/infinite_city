# Design: add-game-menus

- `GameMenu` (CanvasLayer): hidden automatically when headless or when the command line carries
  user arguments (screenshots), else opened at start; `open()` pauses the session clock and the
  player's input; `new_game(name, pronouns)` stores the profile (session part `courier_profile`);
  `continue_game()` loads the quick slot; `apply_settings` saves and applies.
- `GameSettings`: ConfigFile keys input/mouse_sensitivity, game/speed, audio/volume (clamped on
  load); `apply` sets the flight model's sensitivity, the clock speed and the master bus volume.
- `StoryDirector.slot_values(state, courier)` adds `courier` (`first`, `name`, `pronouns`;
  "courier" by default) to the cast for text slots.
- `AddressBook`: lines "who · address" from the job manager (patron, home) and the story cast's
  people and flats; shown in its own `DialoguePanel`.
- `Ambience`: an `AudioStreamGenerator` fed each frame with a 55 Hz hum plus one-pole filtered
  noise; `levels_for(depth)` gives loudness 0.25 → 0.6 and brightness 0.6 → 0.15 over ten layers.
