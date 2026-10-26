# portal-traversal Specification

## Purpose
Makes doorways seamless: you see the other side through them and fly through without any
cut, in both directions, keeping where you are relative to the door and where you are looking.

## Requirements

### Requirement: Doorway pairing
A doorway and the inner door of its pocket space SHALL form a pair. Passing through one maps a
pose relative to that door onto the same pose relative to the other door, turned around so that
what is in front of one door continues behind the other.

#### Scenario: Points in front map behind
- **WHEN** a point 2 m in front of and 1 m above the bottom centre of the outer door is mapped through the pair
- **THEN** it lands 2 m behind and 1 m above the bottom centre of the inner door, within 1 mm

#### Scenario: Mapping back and forth is the identity
- **WHEN** 50 arbitrary poses are mapped from the outer to the inner door and back
- **THEN** every pose returns to itself within 1 mm and 0.001 rad

#### Scenario: Motion into the doorway continues into the room
- **WHEN** a direction pointing into the outer doorway is mapped through the pair
- **THEN** it points away from the inner door into the room

### Requirement: Live view through the doorway
The active doorway SHALL show what lies beyond it, rendered from the viewer's pose mapped
through the doorway pair; while the player is inside a pocket space its inner door SHALL show
the city outside the same way.

#### Scenario: Portal camera follows the viewer
- **WHEN** the camera is 30 m in front of the active doorway
- **THEN** the portal camera's pose equals the camera's pose mapped through the doorway pair, within 1 mm

#### Scenario: Looking back at the city from inside
- **WHEN** the player is inside a pocket space
- **THEN** the portal camera's pose equals the camera's pose mapped from the inner door to the outer door

#### Scenario: Nothing in front of the far door blocks the view
- **WHEN** the camera looks straight at the active doorway from 30 m in front of it
- **THEN** the portal camera does not draw anything closer than the far door (its near plane lies between 29 m and 30 m)

### Requirement: Crossing a doorway
When the camera crosses a door's plane from its front to its back within the 4 m × 6 m opening,
the player SHALL be moved through the pair in the same frame: position relative to the door,
view direction and velocity are preserved through the mapping.

#### Scenario: Entering a pocket space
- **WHEN** the camera flies from 1 m in front to 1 m behind an active outer doorway through its opening
- **THEN** the camera is 1 m in front of the inner door, inside the pocket space, within 1 cm
- **AND** its view direction is the mapped view direction

#### Scenario: Leaving a pocket space
- **WHEN** the camera then flies through the inner door the same way
- **THEN** it is back in the city 1 m in front of the outer doorway, within 1 cm

### Requirement: Doorways are one-sided
Crossing a door's plane from its back, or crossing the plane outside the opening, SHALL NOT move
the player.

#### Scenario: From behind
- **WHEN** the camera crosses the outer doorway's plane from back to front within the opening
- **THEN** it is not moved

#### Scenario: Beside the opening
- **WHEN** the camera crosses the outer doorway's plane from front to back 3 m to the side of the opening
- **THEN** it is not moved
