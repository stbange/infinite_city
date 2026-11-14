# Proposal: add-plot-templates-2

## Why

M17 of the plan (draft 2): two playthroughs on two seeds should tell different stories. Three
templates repeated too soon.

## What Changes

- **New templates:** *The Blackout* (a sabotaged power line, an engineer and a saboteur; restore
  the light, expose the power company or take the gang's money), *The Fall of a House* (a dying
  head of a faction, an heir, a usurper and a ledger) and *The Descent* (pilgrims, a prophet, a
  skeptic and a door below). They use the meeting trigger and new cargo tiers.
- **Choosing:** the per-seed choice now scores six templates (a power company favours the
  Blackout, a faith the Descent).

## Capabilities

### Modified Capabilities
- `story-director`: six templates.

## Impact

- New `data/plot_blackout.json`, `plot_fall_of_a_house.json`, `plot_descent.json`; table schemas;
  `StoryDirector.TEMPLATES`, scores; the template checks cover them.
