# Proposal: add-game-foundations

## Why

The Fogline game (courier jobs, residents, history, story) needs shared machinery before any of
it can be built: game time with a day and night, a way to interact with things, saving, content
tables that designers can edit, generated names, text templates, and background computation for
expensive generators. This is milestone M0 of the Fogline implementation plan.

## What Changes

- **Game time:** a clock (year, day, hour, minute, weekday) that starts in year 517 at 07:00 and
  runs one game day per 48 real minutes; the Light dims from 22:00 to 06:00 and the sun, sky haze
  and fog's sunlit haze follow it.
- **Interaction:** the E key interacts while walking (flying up stays on Space); the HUD shows a
  prompt for the nearest interactive thing in front of the player — for now the doors of flats and
  units in entered blocks ("Door · Fl 12 · Unit 4").
- **Saves:** a game session saves and loads the seed, the clock, the player's absolute position,
  view and mode as versioned JSON in `user://saves/`.
- **Content data:** JSON tables in `res://data/` with a schema check; a deterministic name
  generator with naming cultures; text templates with slots and variants.
- **Background jobs:** a cache of results computed on worker threads, keyed by id.
- **Unique salts:** every hash salt in `src/core/` is unique.

Out of scope (later milestones): residents behind the doors (M2), courier jobs (M4), the event
log and world changes in saves (M9).

## Capabilities

### New Capabilities
- `game-time`: clock and the Light's day–night cycle.
- `interaction`: the interact key, targets and the prompt.
- `save-games`: saving and loading the session.
- `content-data`: data tables, names, text templates, background jobs and salts.

### Modified Capabilities
(none)

## Impact

New: `src/core/game_clock.gd`, `name_generator.gd`, `data_tables.gd`, `text_template.gd`,
`src/world/game_session.gd`, `background_jobs.gd`, `interaction.gd`, `data/`. Changed:
`project.godot` (interact action), `player.gd`, `hud.gd`, `city_world.gd`, `city_fog.gd`,
`interior_view.gd`, `interior_manager.gd`, `main.tscn`.
