# Proposal: add-story-director

## Why

M7 of the Fogline plan: the meta plot. The city already knows its factions, residents and the
courier's patron; a plot template now casts its roles from them and runs its beats on deliveries
and choices, so every seed tells the same story skeleton with its own people. Acts 1 and 2 of
"The Hidden Abundance" become playable.

## What Changes

- **Plot template as data:** `data/plot_hidden_abundance.json` holds roles (patron, keeper,
  friend, rival; monopolist, disruptor and idealist factions), beats with preconditions (finished
  beats, flags, deliveries, deliveries since a beat) and triggers (a scene, or a story delivery to
  a cast person followed by a scene), and scenes with slots and choices.
- **Casting:** the patron's oldest staff member is the patron; residents near the start fill the
  person roles by age, nearest block first, nobody twice; local factions (then city-wide powers)
  of the right type fill the faction roles, preferring a company that controls food.
- **Story state and runner:** beats start one at a time; story jobs appear first in the courier's
  bag and their delivery opens the scene; choices set flags and may raise heat with a cast gang;
  the state is saved. The HUD shows the current objective.
- **Dialogue:** a panel shows the scene with the cast's names filled in and numbered choices
  (keys 1–3).

## Capabilities

### New Capabilities
- `story-director`: plot templates, casting, beats and story state.
- `dialogue`: the scene panel and choices.

## Impact

- New `src/core/story_state.gd`, `story_director.gd`, `src/world/story_runner.gd`,
  `src/world/dialogue_panel.gd`; `DeliveryJob.story_beat`; `JobManager.delivered` signal;
  data table `plot_hidden_abundance`; HUD objective; main scene; tests
  `test/unit/test_story_director.gd`, `test/integration/test_story_runner.gd`.
