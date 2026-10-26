# city-bridges Specification

## Purpose
Lets people cross the city on foot by connecting neighbouring floating blocks with bridges,
placed reproducibly so every visitor sees the same walkways.

## Requirements

### Requirement: Bridges join neighbouring blocks
A bridge SHALL connect exactly two blocks in cells that are adjacent along the X or the Z axis
on the same layer. Bridges never touch open-air cells and never run vertically.

#### Scenario: Bridges only join two blocks
- **WHEN** all X and Z neighbour pairs among 5000 cells below the roof are examined with seed 1337
- **THEN** every bridge found joins two cells that both hold a block
- **AND** every bridge runs along the X or the Z axis

### Requirement: Bridge frequency
About 30% of the eligible neighbour pairs (both cells hold a block) SHALL be connected by a
bridge with the default configuration.

#### Scenario: Share of bridged pairs
- **WHEN** 4000 eligible neighbour pairs are examined with the default configuration
- **THEN** between 22% and 38% of them are bridged

### Requirement: Bridge geometry
A bridge deck SHALL be 6 m wide and run straight along its axis from the facing side of one
block to the facing side of the other. Its centre line lies within the vertical and lateral
extent of both blocks.

#### Scenario: Deck spans face to face
- **WHEN** 500 bridges are examined
- **THEN** each deck starts on the facing side of its first block and ends on the facing side of its second block, within 1 cm

#### Scenario: Deck lies within both blocks
- **WHEN** 500 bridges are examined
- **THEN** each deck's full width lies within the lateral extent of both blocks
- **AND** each deck's height lies within the vertical extent of both blocks

### Requirement: Bridges are seen from both ends
The bridge between two blocks SHALL be reported identically when listing the bridges of either block.

#### Scenario: Listing from either block
- **WHEN** the bridges of block A and of its bridged neighbour B are listed
- **THEN** the bridge between them appears in both lists with identical geometry

### Requirement: Bridge ownership by chunk
Each bridge SHALL belong to exactly one chunk: the chunk containing the bridge's block with the
lower coordinate along the bridge axis.

#### Scenario: Bridges are generated once
- **WHEN** a 3 × 2 × 3 group of chunks is generated
- **THEN** every bridge between two blocks inside the group appears in exactly one chunk
- **AND** that chunk is the one containing the bridge's lower-coordinate block
