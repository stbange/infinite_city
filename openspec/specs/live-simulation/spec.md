# live-simulation Specification

## Purpose
Daily ticks of the districts the courier knows: gangs take bridges, prices follow the blight, residents die and move.

## Requirements

### Requirement: Daily ticks in the live area
Once per game day each live district (the start and every district walked in) SHALL tick
deterministically: gangs may take bridges, food prices drift or climb with the shortage, and
residents may die or move; cast characters never die or move by chance.

#### Scenario: Deterministic ticks
- **WHEN** the same day is ticked twice from the same log
- **THEN** the same events come out

#### Scenario: A week in the district
- **WHEN** a live district is ticked for seven days
- **THEN** some bridge has changed hands and prices have moved, and every event follows the rules

#### Scenario: Prices climb with the shortage
- **WHEN** the shortage has begun and a district is ticked for a few days
- **THEN** its food price climbs toward three times normal

#### Scenario: The cast is safe
- **WHEN** many days are ticked with the story's cast protected
- **THEN** no cast character dies or moves

### Requirement: The changed world in play
The game SHALL tick the live area as days pass, keep what changed in the saved event log, pay
orders by the district's food price, and stop orders from the dead.

#### Scenario: Still true after reloading
- **WHEN** days pass, the session is saved and loaded into a fresh game
- **THEN** the bridge claims, prices and residents are the same as before
