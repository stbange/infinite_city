## ADDED Requirements

### Requirement: Lifts
Blocks of ten floors or more SHALL have a lift in the stair core that takes the courier to the
ground floor, the top floor or five floors up or down, and that routes use.

#### Scenario: Lifts in tall blocks
- **WHEN** a route from the ground floor to the top of a tall block is found
- **THEN** it costs less than climbing every flight

#### Scenario: Taking the lift
- **WHEN** the courier takes the lift from the ground floor to the top
- **THEN** they stand on the top floor of the same block
