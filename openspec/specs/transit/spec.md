# transit Specification

## Purpose
Getting around a city too big to walk: transit hubs between districts and lifts in tall blocks.

## Requirements

### Requirement: Transit hubs
Every district SHALL have a transit hub whose platform links to its neighbouring districts and,
from express rows, to express hubs four rows away; rides cost a fare unless the courier holds a
transit pass, take a few minutes and end at the destination's platform.

#### Scenario: Every district has a hub
- **WHEN** the districts around the start are examined
- **THEN** each has a hub platform in its own transit-hub block

#### Scenario: Links are symmetric
- **WHEN** the links of a column of districts are examined
- **THEN** every link goes both ways, express rows reach four rows away, nothing links into the sky, and express rides cost more

#### Scenario: Riding to a neighbouring district
- **WHEN** the courier picks the first ride at a hub, and later rides back with a transit pass
- **THEN** they stand at the destination's platform, the fare is paid and time has passed, and the ride back is free

#### Scenario: No ride without the fare
- **WHEN** a courier without money tries to ride
- **THEN** they stay where they are and are told the fare

### Requirement: Lifts
Blocks of twelve floors or more (roughly a quarter to a third of blocks) SHALL have a lift in the stair core that takes the courier to the
ground floor, the top floor or five floors up or down, and that routes use.

#### Scenario: Lifts in tall blocks
- **WHEN** a route from the ground floor to the top of a tall block is found
- **THEN** it costs less than climbing every flight

#### Scenario: Taking the lift
- **WHEN** the courier takes the lift from the ground floor to the top
- **THEN** they stand on the top floor of the same block
