# traversal-tools Specification

## Purpose
The tools that change how the courier moves: grapple, glider, scanner beacon and flares.

## Requirements

### Requirement: Grapple
With the grapple, aiming at a surface within 20 m and pressing G SHALL pull the courier onto it;
farther surfaces are out of reach.

#### Scenario: Within and beyond reach
- **WHEN** the courier grapples a ledge 18 m away, and another one 22 m away
- **THEN** the first pulls them onto it and the second does nothing

### Requirement: Glider
With the glider, holding Space while falling SHALL cap the fall at 3 m/s and carry the courier
forward.

#### Scenario: Gliding down
- **WHEN** a courier falls for two seconds with the glider open, and another without it
- **THEN** the glider's fall speed stays at or below 3 m/s and the other falls faster

### Requirement: Scanner and flares
The scanner SHALL show a beacon at the next door within 200 m for ten seconds; a flare SHALL end a
chase at once and be used up.

#### Scenario: Scanning for the door
- **WHEN** the courier scans with a job whose door is within 200 m
- **THEN** a beacon stands at the door

#### Scenario: A flare in a chase
- **WHEN** the courier fires a flare while chased
- **THEN** the chase ends with the cargo kept and one flare fewer
