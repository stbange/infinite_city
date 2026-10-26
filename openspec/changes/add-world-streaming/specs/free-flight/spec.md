# Spec Delta

## Purpose

Lets the player fly freely through the canyons of the city in every direction and always know
where they are in it.

## ADDED Requirements

### Requirement: Six-degree-of-freedom flight
The player SHALL fly forward/back and left/right relative to the view direction, and up/down
along the world vertical, at a cruise speed of 40 m/s by default.

#### Scenario: Flying forward
- **WHEN** the view faces -Z and forward is held for 1 second
- **THEN** the camera moves 40 m along -Z within 1 cm

#### Scenario: Flying up while looking down
- **WHEN** the view is pitched 60° downward and up is held for 0.5 seconds
- **THEN** the camera moves 20 m along +Y within 1 cm and does not move horizontally

#### Scenario: Diagonal input is not faster
- **WHEN** forward and right are held together for 1 second
- **THEN** the camera moves 40 m within 1 cm

### Requirement: Boost
Holding boost SHALL multiply the flight speed by 6.

#### Scenario: Boosted flight
- **WHEN** forward and boost are held for 1 second
- **THEN** the camera moves 240 m within 1 cm

### Requirement: Mouse look
Horizontal mouse motion SHALL turn the view without limit; vertical motion SHALL pitch the view,
clamped to ±89° so the view never flips over.

#### Scenario: Pitch is clamped
- **WHEN** the mouse moves far enough upward to pitch the view by 200°
- **THEN** the view's pitch is 89°

### Requirement: Location read-out
The view SHALL show the camera's absolute cell, its depth below the roof in layers and metres,
its district, and the function of the block the camera is inside, or "Open air" when it is not
inside a block.

#### Scenario: Read-out content
- **WHEN** the camera is in open air in cell (3, -12, 5) with the default configuration
- **THEN** the read-out contains "Cell 3, -12, 5", "Depth 12 layers (768 m)", "District 0, -2, 0" and "Open air"

#### Scenario: Inside a block
- **WHEN** the camera is inside a hospital block
- **THEN** the read-out contains "Inside: Hospital" and not "Open air"

#### Scenario: Above the roof
- **WHEN** the camera is in cell (0, 2, 0)
- **THEN** the read-out shows "Altitude 2 layers above the roof" instead of a depth

### Requirement: Starting point
The game SHALL start the player 2 layers above the roof at the rim of the shaft nearest to the
origin, looking down into it, so the first view shows both the roof and a way down.

#### Scenario: Start at a shaft
- **WHEN** the start point is computed with seed 1337
- **THEN** the camera is 2 layers above the roof and horizontally within 2 cells of a shaft cell
- **AND** the view is pitched downward and faces the shaft centre
