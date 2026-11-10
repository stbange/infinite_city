# flying-traffic Specification

## Purpose
Flying cars in the major lanes, positioned as a pure function of lane and time, and what happens when one hits the courier.

## Requirements

### Requirement: Cars in the major lanes
Flying cars SHALL travel along the major lanes in both directions, at positions that are a pure
function of lane and time, moving continuously and never inside a block.

#### Scenario: Cars only in lanes, never in blocks
- **WHEN** the cars within 300 m of several points of the city are listed
- **THEN** every car lies in the gap of a major lane and inside no block

#### Scenario: Continuous and deterministic
- **WHEN** the same cars are listed a tenth of a second later, and again by a new generator
- **THEN** each car has moved by its velocity times the interval, and the new generator lists the same cars

### Requirement: Car hits
A courier touching a car SHALL be knocked out of the lane and rescued.

#### Scenario: Hit by a car
- **WHEN** the player stands where a car is passing
- **THEN** the rescue drone puts them back on safe ground
