## ADDED Requirements

### Requirement: Floors inside the outer walls
Floor slabs and the roof slab SHALL lie inside the outer walls. Each floor's outer walls SHALL
reach from its walking surface to the next floor's walking surface (the top floor's to the roof),
and floor 0's outer walls SHALL reach down to the bottom of its slab, so that the outer walls form
one closed façade from the bottom of the lowest slab to the roof.

#### Scenario: Slabs within the inner footprint
- **WHEN** every floor of 30 blocks is examined
- **THEN** every floor slab and roof slab lies within the plan's inner rectangle (inside the outer walls)

#### Scenario: Closed façade
- **WHEN** every floor of 30 blocks is examined
- **THEN** the outer wall pieces of floor k span heights from the floor's level to 4 m above it, and those of floor 0 start 0.3 m below its level

### Requirement: No overlapping surfaces
Drawn boxes of different materials — façade (outer walls, roof, hut), glass, floor slabs, inner
walls, stairs (steps and stair solids), furniture and lights — SHALL NOT overlap, within a floor
or between neighbouring floors, so that no two materials compete for the same surface.

#### Scenario: Nothing fights for a surface
- **WHEN** floors 0, 1, the middle floor and the top floor of 20 blocks are examined, each together with the floor above it
- **THEN** no two drawn boxes of different materials overlap by more than 2 mm along every axis

## MODIFIED Requirements

### Requirement: Stairs connect all floors and the roof
Every block SHALL have a stair core next to the corridor crossing, inside the walls of its unit:
two flights per floor, each 1.6 m wide rising 2 m over 3 m, from the lowest floor up to a hut on
the roof with a door.

#### Scenario: Flights per floor
- **WHEN** the floors of 50 blocks are examined
- **THEN** each floor has two flights rising 2 m each, the first starting at the floor's level and the second ending at the next floor's level
- **AND** the floor above has an opening over the flights

#### Scenario: Roof access
- **WHEN** the plan of a block is examined
- **THEN** the top floor's second flight ends at the roof and a hut with a door opening stands over the stair core

#### Scenario: Stair core inside its unit
- **WHEN** the plans of 50 blocks are examined
- **THEN** the stair core lies inside its unit and starts on the inner face of the unit's side wall next to the corridor
