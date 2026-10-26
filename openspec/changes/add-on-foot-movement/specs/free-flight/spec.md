# Spec Delta

## MODIFIED Requirements

### Requirement: Starting point
When the game starts in flight mode, it SHALL place the player 2 layers above the roof at the rim
of the shaft nearest to the origin, looking down into it, so the first view shows both the roof
and a way down.

#### Scenario: Start at a shaft
- **WHEN** the start point is computed with seed 1337
- **THEN** the camera is 2 layers above the roof and horizontally within 2 cells of a shaft cell
- **AND** the view is pitched downward and faces the shaft centre
