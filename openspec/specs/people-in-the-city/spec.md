# people-in-the-city Specification

## Purpose
Figures for the people around the player, placed by their routines: at work, out, at home or walking their routes, within a fixed budget of figures and frame time.

## Requirements

### Requirement: People where their routine puts them
People of the blocks around the player SHALL appear as figures where their routine puts them at
the current game time: inside their workplace during their shift, inside the venue when out,
inside their flat when awake at home, and nowhere while asleep.

#### Scenario: Workers behind the counter
- **WHEN** the player stands near a workplace during an hour when some of its staff are on shift
- **THEN** a figure for each of them stands inside that workplace's unit

#### Scenario: Sleepers out of sight
- **WHEN** the player stands in a housing block at 03:00
- **THEN** no figure is shown for anyone whose routine says they are asleep

### Requirement: Walking routes
People on the way SHALL walk their route through corridors, stairs and bridges at walking pace
from the start of the walk, and wait at their destination when they arrive early.

#### Scenario: A commuter on the route
- **WHEN** a figure is shown for someone commuting and game time passes
- **THEN** the figure stands on their route at the distance walked since the commute began, moving forward

### Requirement: Figures near the player
At most 40 figures SHALL be shown, the nearest first, all within 60 m of the player, and a figure
in reach SHALL be an interaction target naming the person and what they are doing.

#### Scenario: Figure cap
- **WHEN** the player stands in a busy block during the morning rush
- **THEN** at most 40 figures are shown and all are within 60 m of the player

#### Scenario: Looking at a person
- **WHEN** the player faces a figure within reach
- **THEN** the interaction prompt names the person, their age and their activity

### Requirement: Walking figures and gossip
Figures SHALL swing their legs while they move; pressing E on a figure SHALL show a piece of gossip
they know.

#### Scenario: A walker swings their legs
- **WHEN** a commuter's figure moves along its route
- **THEN** its walking animation advances
