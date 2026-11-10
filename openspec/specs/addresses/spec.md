# addresses Specification

## Purpose
Place names for layers, districts and blocks, door addresses that format and parse both ways, and floor signs at the stairs, so a courier can find a door in the fog.

## Requirements

### Requirement: Place names
Every district SHALL have a name unique within its Reach; every block is named after its district
and its number within the district (1–512), for example "Copper-217"; every layer is labelled
relative to the roof ("L0" for the roof layer, "L-19" nineteen layers below).

#### Scenario: Unique district names
- **WHEN** the district names of 20 Reaches are examined
- **THEN** no two districts of the same Reach share a name

### Requirement: Addresses
A door's address SHALL read "<layer> · <Reach> · <block> · Fl <floor from 1> · Unit <unit from 1>",
and parsing an address near the door SHALL give back the same block, floor and unit.

#### Scenario: Round trip
- **WHEN** 2,000 doors of random blocks are formatted and parsed back near their block
- **THEN** every parse gives the same cell, floor and unit

### Requirement: Floor signs
Entered blocks SHALL show the floor number at the stair core of the player's floor and the floors next to it.

#### Scenario: Floor numbers at the stairs
- **WHEN** the player is on floor index 3 of an entered block
- **THEN** floor signs reading "Fl 3", "Fl 4" and "Fl 5" exist at its stair core
