# Proposal: add-game-menus

## Why

M10 polish: the game needs a front door and the small comforts of a game — naming your courier,
settings that stick, a list of the addresses that matter, and a sound for the fog.

## What Changes

- **Main menu:** new game with the courier's name and pronouns, continue from the quick save,
  settings, quit; shown at start in a normal run and on Esc; the game waits while it is open. The
  courier's name appears in scenes ({courier.first}) and is saved.
- **Settings:** mouse sensitivity, game speed and volume, kept in `user://settings.cfg`.
- **Address book (M):** the patron, home and the story's people and places with their addresses.
- **Ambience:** a procedural hum and filtered noise, louder and darker deeper below the roof.

## Capabilities

### New Capabilities
- `game-menus`: main menu, courier profile, settings, address book and ambience.

## Impact

- New `src/core/game_settings.gd`, `src/world/game_menu.gd`, `address_book.gd`, `ambience.gd`;
  `StoryDirector.slot_values`; `StoryRunner.menu_path`; HUD controls; main scene; tests
  `test/integration/test_game_menus.gd`.
