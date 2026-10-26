# Spec Delta

## ADDED Requirements

### Requirement: Solid pocket spaces
A pocket space SHALL be solid: its floor, walls, ceiling, pillars, props and monument collide,
and its inner door is an open gap in the entrance wall.

#### Scenario: Standing in a pocket space
- **WHEN** a walking player arrives in a pocket space and 1 s of physics passes
- **THEN** the player stands on the floor within 5 cm

#### Scenario: The inner door is open
- **WHEN** the collision shapes of the entrance wall are examined
- **THEN** none of them overlaps the 4 m × 6 m opening of the inner door
