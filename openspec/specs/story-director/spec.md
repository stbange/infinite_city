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

### Requirement: The full arc and its endings
The first arc SHALL run through five acts to one of four endings chosen at the vault; a cast
character SHALL die only through a plot beat, recorded in the event log; endings SHALL change the
district through the event log.

#### Scenario: Every path ends the story
- **WHEN** every sequence of deliveries and choices of the template is explored
- **THEN** from every reachable state the end of the story can still be reached

#### Scenario: Endings change the district
- **WHEN** the story is played to the ending that opens the vault to everyone, and again to the one that gives it to the gang
- **THEN** the keeper's death is in the event log, and food prices fall in the first case while the gang takes the bridges around the patron in the second

### Requirement: Several templates
The story director SHALL hold several plot templates — the Hidden Abundance, the Election and the
Plague — each castable from the world and free of dead ends, and SHALL choose one per seed by its
fit with the start's Reach.

#### Scenario: Every template is complete
- **WHEN** each template is cast and its beat graph explored
- **THEN** every role is filled, every path can reach the end of the story, and no slot is left unfilled

#### Scenario: Choosing a template
- **WHEN** the template is chosen for twelve seeds, twice each
- **THEN** each choice is repeatable and more than one template is chosen
