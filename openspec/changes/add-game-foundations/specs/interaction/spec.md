## ADDED Requirements

### Requirement: Interact key
While walking, the E key SHALL interact with the current target; flying up SHALL stay on Space
(and no longer on E).

#### Scenario: Key bindings
- **WHEN** the input map is examined
- **THEN** the interact action is bound to E and the fly-up action is not

### Requirement: Interaction targets
The current target SHALL be the nearest interactive thing within 2.5 m of the player's eyes and
within 45° of the view direction. Unit doors in entered blocks are interactive, labelled with the
floor (counted from 1) and the unit (counted from 1).

#### Scenario: Facing a door
- **WHEN** the player stands 1.5 m in front of a unit door in an entered block, facing it
- **THEN** the target is that door and its label names the floor and the unit

#### Scenario: Looking away
- **WHEN** the same player turns around
- **THEN** there is no target

### Requirement: Prompt
The HUD SHALL show "E · " followed by the target's label while there is a target, and nothing
otherwise.

#### Scenario: Prompt follows the target
- **WHEN** the player faces a door and then turns away
- **THEN** the prompt shows the door's label and then disappears
