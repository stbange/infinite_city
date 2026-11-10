# story-director Specification

## Purpose
The meta plot: plot templates as data, casting their roles from the factions and residents around the start, beats driven by deliveries and choices, and the saved story state.

## Requirements

### Requirement: Casting from the world
Every role of the plot template SHALL be cast from the world around the start — the patron's staff,
residents of nearby housing blocks by age, factions of the start's Reach — deterministically and
with nobody cast twice.

#### Scenario: Every role filled
- **WHEN** the plot is cast around the start of 8 different seeds
- **THEN** every role is filled, no person or faction holds two roles, and person roles fit their age ranges

#### Scenario: Deterministic cast
- **WHEN** the same start is cast twice by new generators
- **THEN** the casts are equal

### Requirement: Beats
Beats SHALL start one at a time when their preconditions hold, wait for a scene choice or a story
delivery, and every beat and the end of Act 2 SHALL be reachable whatever the courier chooses.

#### Scenario: No dead ends
- **WHEN** every sequence of deliveries and choices is explored
- **THEN** every beat is reached on some path, and from every reachable state the end of Act 2 can still be reached

#### Scenario: Scenes name the cast
- **WHEN** every scene and choice of the template is filled with a cast
- **THEN** no slot is left unfilled

### Requirement: Story runner
The game SHALL run the story on deliveries: story jobs to cast residents go first in the bag,
delivering one opens its scene, choices change the story state, and the state is saved.

#### Scenario: Acts 1 and 2 on deliveries and choices
- **WHEN** the courier delivers orders and story jobs and picks choices
- **THEN** the beats of Acts 1 and 2 run in order and the story ends Act 2

#### Scenario: Saved story
- **WHEN** the session is saved mid-story and loaded
- **THEN** the cast, flags, finished beats and active beat come back
