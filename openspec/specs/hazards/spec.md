# hazards Specification

## Purpose
The rescue drone that picks up a courier after a fall or a car hit, for a fee and the cargo.

## Requirements

### Requirement: Rescue drone
After a fall or a car hit the courier SHALL be put back on the last safe ground, pay a ¤25 fee (all
they have if less) and lose the carried cargo, and the HUD SHALL say what happened.

#### Scenario: Rescued after a fall
- **WHEN** the fall safety net puts the courier back while they carry an order
- **THEN** the fee is taken, the order is lost and the HUD names the rescue

#### Scenario: Fee when broke
- **WHEN** a courier with ¤10 is rescued
- **THEN** they are left with ¤0
