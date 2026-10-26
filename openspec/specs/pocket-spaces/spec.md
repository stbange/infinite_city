# pocket-spaces Specification

## Purpose
Defines the bigger-on-the-inside spaces behind doorways: how vast they are, what they contain,
where they live so they are never seen from outside except through their doorway, and when
they exist.

## Requirements

### Requirement: Bigger on the inside
The pocket space behind a doorway SHALL have at least ten times the volume of the block that
holds the doorway, and its width and depth SHALL each be at least twice the block's largest
horizontal size.

#### Scenario: Interior dwarfs the block
- **WHEN** the pocket spaces of 300 doorways are examined
- **THEN** each one's volume is at least ten times its block's volume
- **AND** each one's width and depth are at least twice its block's largest horizontal size

### Requirement: Interior kind follows the block
The kind of pocket space SHALL follow the function of its block: markets open into a bazaar,
parks and farms into a garden, transit hubs into a concourse, and every other block into a hall.

#### Scenario: Kinds by function
- **WHEN** doorways of a market, a park, a farm, a transit hub and a housing block are examined
- **THEN** their pocket spaces are a bazaar, a garden, a garden, a concourse and a hall respectively

### Requirement: Deterministic interiors
The size, kind and contents of a pocket space SHALL be a pure function of the seed and the
doorway's cell.

#### Scenario: Same interior every time
- **WHEN** the pocket space of the same doorway is generated twice by independent generators
- **THEN** size, kind, inner door and contents are identical

### Requirement: Inner door
Each pocket space SHALL have one inner door, 4 m by 6 m, standing on the floor in the middle of
one wall and facing into the room.

#### Scenario: Inner door on the entrance wall
- **WHEN** a pocket space is generated
- **THEN** its inner door's bottom centre is on the floor at the middle of one wall
- **AND** the door faces into the room

### Requirement: Out of sight
Pocket spaces SHALL be placed 12 km above their doorway, beyond the camera's 3 km view distance
plus the size of any pocket space, so that they are never seen from the city and the city is
never seen from inside them except through a doorway.

#### Scenario: Separation from the city
- **WHEN** a pocket space is activated for a doorway
- **THEN** every point of the pocket space is more than 3 km away from every point of the city within 3 km of the doorway

### Requirement: One active pocket space
At most one pocket space SHALL exist at a time: the one belonging to the doorway the player is
inside, or else to the nearest doorway within 160 m of the camera. It is released when neither
holds.

#### Scenario: Approaching a doorway
- **WHEN** the camera moves to 30 m in front of a doorway with no other doorway closer
- **THEN** exactly one pocket space exists and it belongs to that doorway

#### Scenario: Leaving the area
- **WHEN** the camera then moves more than 160 m away from every doorway
- **THEN** no pocket space exists

### Requirement: Read-out inside a pocket space
While the player is inside a pocket space, the location read-out SHALL name the pocket space,
its size and the cell of the block it belongs to.

#### Scenario: Read-out inside
- **WHEN** the player is inside the bazaar behind the market block in cell (4, -3, 7)
- **THEN** the read-out contains "Bazaar", the size in metres and "behind cell 4, -3, 7"
