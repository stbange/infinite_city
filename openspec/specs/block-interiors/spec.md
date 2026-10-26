# block-interiors Specification

## Purpose
Makes blocks enterable: each block has floors, corridors, stairs and units — flats with rooms and
furniture, shops, offices and more — that the player can walk into from the bridges.

## Requirements

### Requirement: Floors
A block SHALL have one floor per 4 m of height; floor k's walking surface is 4k m above the
block's bottom, and the block's top is its roof.

#### Scenario: Floor levels
- **WHEN** the plans of 200 blocks are examined
- **THEN** each plan has height / 4 floors and floor k lies 4k m above the bottom

### Requirement: Corridors reach every face
Every floor SHALL have a corridor 2.5 m wide along the line through the cell centre in each
horizontal direction, running from face to face, so that every face can be reached from inside.

#### Scenario: Corridor cross
- **WHEN** the plans of 200 blocks are examined
- **THEN** each has a corridor centred on x = 0 reaching both z faces and a corridor centred on z = 0 reaching both x faces

### Requirement: Units open onto corridors
The rest of each floor SHALL be divided into units, each a rectangle inside the outer walls that
overlaps neither a corridor, the stair core nor another unit, and whose front side lies on a
corridor with a door 1 m wide in it.

#### Scenario: Units and doors
- **WHEN** the plans of 200 blocks are examined
- **THEN** every unit lies inside the outer walls and overlaps no corridor, no other unit and not the stair core
- **AND** every unit's door lies on the unit's front side and on the edge of a corridor

### Requirement: Stairs connect all floors and the roof
Every block SHALL have a stair core next to the corridor crossing: two flights per floor, each
1.6 m wide rising 2 m over 3 m, from the lowest floor up to a hut on the roof with a door.

#### Scenario: Flights per floor
- **WHEN** the floors of 50 blocks are examined
- **THEN** each floor has two flights rising 2 m each, the first starting at the floor's level and the second ending at the next floor's level
- **AND** the floor above has an opening over the flights

#### Scenario: Roof access
- **WHEN** the plan of a block is examined
- **THEN** the top floor's second flight ends at the roof and a hut with a door opening stands over the stair core

### Requirement: Entrances
Where a bridge meets a block, the block SHALL have an entrance on that floor: an opening 2 m wide
and 3 m tall at the end of the corridor on that face, starting at the deck. Where a magic doorway
stands at the bridge's end, there is no entrance.

#### Scenario: Entrances at bridges
- **WHEN** the plans of 300 blocks with bridges are examined
- **THEN** each bridge without a magic doorway at that end has an entrance on the floor at its deck height and the face where it arrives
- **AND** no entrance exists where no bridge arrives

### Requirement: Windows
The outer walls SHALL have windows where the façade shows them: in every 4 m bay of the world grid,
1.6 m wide and 1.68 m tall starting 1.2 m above the floor, except where a bay is cut by the
block's edge or meets a corridor end.

#### Scenario: Window grid
- **WHEN** the windows of 50 floors are examined
- **THEN** every window lies within its face, starts 1.2 m above its floor, is 1.6 m × 1.68 m and spans the middle of a world-grid bay

### Requirement: Flats
Every housing unit SHALL be a flat containing at least a bed, a sofa or chairs, a table, a kitchen
counter and a bathroom with a shower, a toilet and a sink.

#### Scenario: Furnished flats
- **WHEN** 200 housing units are furnished
- **THEN** each contains a bed, a sofa or chair, a table, a kitchen counter, a shower, a toilet and a sink

### Requirement: Themed units
Units of other blocks SHALL be furnished for their function: offices with desks and screens,
markets with shelves and a counter, farms with grow racks, industry with machines, parks with
planters, hospitals with beds, schools with desks and a board, and services with their consoles,
lockers or benches.

#### Scenario: Signature items
- **WHEN** 30 units of each function are furnished
- **THEN** every office unit has a desk, every market unit a shelf, every farm unit a grow rack, every industry unit a machine, every park unit a planter, every hospital unit a bed and every school unit a board

### Requirement: Tidy furniture
Furniture SHALL stand inside its room, not overlap other furniture or walls, and keep a 1 m deep
area in front of every door free.

#### Scenario: Nothing in the way
- **WHEN** 100 floors are furnished
- **THEN** every item lies inside its room, overlaps no other item, and stays out of every door's clear area

### Requirement: Room light
Every room SHALL have a ceiling light; room light colours are warm, cool or neon so that
interiors stay dim and moody. While the player is inside an entered block, the room lights of the
player's floor, and of no other floor, SHALL be offered as light anchors to the city's light pool.

#### Scenario: Lit rooms
- **WHEN** 50 floors are examined
- **THEN** every room has at least one light inside it, below its ceiling

#### Scenario: Light where the player is
- **WHEN** the player stands in the bedroom of a flat on floor index 2 of an entered block
- **THEN** the light pool has a light inside that bedroom, and every room light offered by the block lies on floor index 2

### Requirement: Deterministic interiors
Plans and furnishing SHALL be a pure function of the seed and the block's cell (and floor).

#### Scenario: Same interior every time
- **WHEN** the same block's plan and its floor 3 are generated by two independent generators
- **THEN** both are identical

### Requirement: Entering blocks
Blocks within 12 m of the player SHALL become enterable — at most two at a time: their interior
is built and their sealed box (drawn and solid) is replaced by the interior's shell, floors,
stairs, walls and furniture. A block is sealed again once the player is more than 30 m away.

#### Scenario: Approaching a block
- **WHEN** the player stands on a bridge 5 m from a block's entrance and enough frames pass to build it
- **THEN** the block's interior exists, its box is hidden and no longer solid

#### Scenario: Walking in
- **WHEN** the player then walks forward through the entrance for 3 s
- **THEN** the player stands on the entrance floor inside the block

#### Scenario: Leaving
- **WHEN** the player moves more than 30 m away from the block
- **THEN** its interior is released and its box is drawn and solid again

### Requirement: Climbing stairs
A walking player SHALL be able to walk up a flight of stairs.

#### Scenario: Up the first flight
- **WHEN** the player stands at the foot of a first flight and walks up it
- **THEN** the player reaches the landing 2 m higher

### Requirement: Read-out inside a block
Inside an entered block the read-out SHALL name the floor (counted from 1) out of the block's
floors and the room the player is in.

#### Scenario: Read-out in a room
- **WHEN** the player stands in the bedroom of a flat on floor index 2 of a 12-floor block
- **THEN** the read-out contains "Floor 3 of 12" and "Bedroom"
