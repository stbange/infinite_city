# Design: add-game-foundations

## Decisions

### D1 — Clock (`GameClock`, pure)
An `int` of game minutes since year 0 plus a fractional accumulator for real-time advance.
Calendar fields derive from it (365-day years, no months). `light_level()` uses smoothsteps over
21:00–23:00 (dusk) and 05:00–07:00 (dawn). `GameSession` owns the clock and pushes the light level
to `CityWorld.daylight`, which scales the sun's energy and the sky haze, and to `CityFog`, which
scales the sun haze.

### D2 — Interaction (`Interaction` node)
Providers return candidate targets `{position, label, kind, payload}` near a point; for now
`InteriorManager.door_targets(near)` lists the unit doors on the player's floor of ready
interiors (door centre at the unit's front wall, 1.1 m above the floor). `Interaction` picks the
nearest candidate within 2.5 m of the eyes and 45° of the view, exposes `target()` and emits
`interacted(target)` when the player presses interact. The Hud shows the prompt. `project.godot`
gets an `interact` action on E; E is removed from `move_up`.

### D3 — Saves (`GameSession`)
`to_dict()` / `from_dict()` with `version = 1`; positions as three 64-bit floats from
`FloatingOrigin.absolute_metres()`; written with `JSON.stringify` to `user://saves/<slot>.json`.
Loading teleports the focus (`CityWorld.teleport_focus`) and restores view, mode and clock.

### D4 — Content data
`DataTables.load_table(name, schema)` reads `res://data/<name>.json` and checks it against a tiny
schema format: `{ "key": "string" | "int" | "float" | "array" | "dict" }`, applied to the root or
to each entry of an array. Name cultures live in `data/names.json` (onsets, vowels, codas, endings
per culture for given and family names). `NameGenerator` builds 1–3 syllables from
`CellRandom(hash(seed, SALT_NAME, id))`. `TextTemplate.fill(text, values, seed)`.

### D5 — Background jobs
`BackgroundJobs` wraps `WorkerThreadPool.add_task`; results are stored under a mutex; `poll()`
on the main thread collects finished tasks. Pure generators make thread use safe.

### D6 — Salt check
A test loads every script in `src/core/`, reads `get_script_constant_map()` and checks SALT_*
values are unique; new systems take salts from 100 upwards.
