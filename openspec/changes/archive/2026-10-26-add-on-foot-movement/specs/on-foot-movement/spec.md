# Spec Delta

## Purpose

Lets the player explore the city on foot in first person: walking along bridges, standing on
roofs and stepping through doorways, with gravity, a solid city around them and a safety net for
the endless fall below.

## ADDED Requirements

### Requirement: Walking
On the ground the player SHALL walk at 4.5 m/s relative to the view's horizontal direction,
reaching full speed within 0.2 s; diagonal input is not faster. The eyes are 1.65 m above the feet.

#### Scenario: Walking forward
- **WHEN** the player stands on the ground facing -Z and walks forward for 0.2 s
- **THEN** the horizontal velocity is 4.5 m/s along -Z within 0.01 m/s

#### Scenario: Looking up does not slow walking
- **WHEN** the view is pitched 60° upward and the player walks forward and right together
- **THEN** the horizontal speed reaches 4.5 m/s and the player does not move vertically

### Requirement: Sprinting
Holding sprint SHALL raise the walking speed to 8 m/s.

#### Scenario: Sprinting
- **WHEN** the player walks forward while holding sprint for 0.3 s
- **THEN** the horizontal speed is 8 m/s within 0.01 m/s

### Requirement: Jumping and gravity
On the ground, jump SHALL launch the player upward at 4.6 m/s (a jump of about 1.1 m); in the air
gravity pulls at 9.81 m/s² and jump does nothing. Steering in the air is weaker than on the ground.

#### Scenario: Jump height
- **WHEN** the player jumps from the ground and the motion is simulated until the vertical speed turns negative
- **THEN** the apex is between 1.0 m and 1.2 m above the start

#### Scenario: No double jump
- **WHEN** jump is pressed while the player is in the air
- **THEN** the vertical speed is not raised

#### Scenario: Falling accelerates
- **WHEN** the player is in the air for 1 s starting at rest
- **THEN** the vertical speed is -9.81 m/s within 0.01 m/s

### Requirement: Solid city near the player
Blocks and bridge decks within one chunk of the player SHALL be solid: the player stands on roofs
and decks and cannot walk through block walls.

#### Scenario: Standing on a bridge
- **WHEN** the player is placed on a bridge deck and 1 s of physics passes
- **THEN** the player stands on the floor with the feet within 5 cm of the deck surface

#### Scenario: Walls stop the player
- **WHEN** the player walks along a bridge towards a block face (without a doorway) for 6 s
- **THEN** the player stops in front of the face and never passes it

### Requirement: Bridge railings
Bridges SHALL have solid railings 1.1 m high along both edges for their whole length, so walking
sideways cannot push the player off a bridge.

#### Scenario: Railings hold the player
- **WHEN** the player on a bridge walks sideways towards an edge for 3 s
- **THEN** the player is still above the deck, within its width

### Requirement: Fall safety net
When the player has been falling for more than 4 s, they SHALL be put back, at rest, at the last
place where they stood on the ground.

#### Scenario: Endless fall
- **WHEN** the player stood on a roof, then falls without landing for 4.1 s
- **THEN** the player is back at the place where they last stood, with zero velocity

#### Scenario: Short falls are fine
- **WHEN** the player falls for 3 s and lands
- **THEN** the player is not moved back

### Requirement: Walking and flying
The player SHALL switch between walking and free flight with the toggle action. While flying,
gravity and collision do not apply; switching back to walking in mid-air makes the player fall.

#### Scenario: Toggle
- **WHEN** the player walks, toggles once and toggles again
- **THEN** the player flies after the first toggle and walks after the second

#### Scenario: Flight ignores walls
- **WHEN** the player flies through a block
- **THEN** nothing stops the movement

### Requirement: Starting on foot
The game SHALL start the player standing on the sunlit roof of a roof-layer block at the rim of
the shaft nearest to the origin, facing the shaft.

#### Scenario: On-foot start
- **WHEN** the on-foot start is computed with seed 1337
- **THEN** the feet are on the top surface of a block in the roof layer, horizontally within 2 cells of a shaft cell
- **AND** the view faces the shaft centre
