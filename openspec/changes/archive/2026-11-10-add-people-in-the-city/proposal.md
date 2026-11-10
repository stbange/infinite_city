# Proposal: add-people-in-the-city

## Why

M5's playable result: the district is alive. The people the city already knows about — their
homes, jobs and routines — should be visible around the player, standing where their routine puts
them and walking their routes, so the noodle bar has its cooks and corridors fill in the morning.

## What Changes

- **People near the player:** residents and staff of the blocks around the player, on the floors
  near the player, appear as simple figures where their routine puts them: at work or out inside
  the unit, awake at home inside their flat, or on their route when walking. Sleeping people stay
  out of sight.
- **Walking:** walkers follow their route at walking pace from the start of the walk and wait at
  the destination when they arrive early; routes are found a few per frame.
- **Limits:** at most 40 figures, the nearest first, within 60 m; routines are cached until their
  segment ends and new candidates are examined a slice per frame.
- **Looking at people:** a figure in reach is an interaction target labelled with name, age and
  what they are doing.

## Capabilities

### New Capabilities
- `people-in-the-city`: figures for people near the player, placed by their routines.

## Impact

- New `src/world/people_manager.gd`, `src/world/person_agent.gd`; `GameClock.exact_minutes()`;
  main scene wiring; tests `test/integration/test_people_in_the_city.gd`.
