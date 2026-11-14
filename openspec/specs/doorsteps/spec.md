# doorsteps Specification

## Purpose
Who answers the door when a delivery arrives, what they say, and how it changes the tip.

## Requirements

### Requirement: Who answers the door
At a delivery the customer SHALL answer when their routine says they are home and awake; asleep
they answer for half the tip; when they are out a household member at home answers; otherwise the
bag is left at the door for a small tip. The person who answers SHALL stand in the doorway and say
a line.

#### Scenario: Who answers
- **WHEN** residents receive deliveries at night, in the morning and in the evening
- **THEN** each answer matches their routine and their household's, with its tip factor and a line

#### Scenario: Tips follow the answer
- **WHEN** the same delivery is paid with different answers
- **THEN** a full answer pays more than a bag left at the door, and no answer pays the base

#### Scenario: The door decides the tip
- **WHEN** the courier delivers to a door
- **THEN** the pay follows the doorstep's answer and whoever answered stands in the doorway
