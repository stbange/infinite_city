# Proposal: add-side-arcs

## Why

M17: regulars should have small stories of their own beside the main arc.

## What Changes

- **Side arcs:** *A Debt*, *A Secret* and *A Missing Child* — two or three beats each, cast from
  residents who are not in the main story, picked per seed.
- **Side runner:** a second story runner plays the side arc beside the main one, sharing the scene
  panel; the HUD shows its objective until it ends.

## Capabilities

### Modified Capabilities
- `story-director`: side arcs.

## Impact

- New `data/plot_side_*.json`; `StoryDirector.SIDE_TEMPLATES`, `pick_side`, `cast(..., exclude)`;
  `StoryRunner.side`, `main_path`, shared-panel guard; `DialoguePanel.choice_count`; HUD; main scene.
