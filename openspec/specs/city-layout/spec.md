# city-layout Specification

## Purpose
Defines the shape of the infinite city: the lattice of cells that hold floating blocks, its
single upper boundary, the canyons that open it up for travel, the geometry of each block and
how regions are generated independently and reproducibly.

## Requirements

### Requirement: Deterministic generation
The city SHALL be a pure function of its seed and integer cell coordinates. Querying the same
cell with the same seed MUST always produce the same result, independent of which other cells
or regions were generated before or in which order.

#### Scenario: Repeated queries agree
- **WHEN** two independent generators with seed 1337 query cell (12, -40, -7)
- **THEN** both report the same occupancy, block function, block size and block offset

#### Scenario: Generation order does not matter
- **WHEN** generator A generates chunk (0, -1, 0) and then chunk (5, -3, 2), and generator B generates them in the reverse order, both with seed 1337
- **THEN** both generators produce identical content for both chunks

#### Scenario: The seed changes the city
- **WHEN** the occupancy of the same 1000 cells below the roof is compared between seed 1 and seed 2
- **THEN** at least 20% of the cells differ

### Requirement: Cell lattice
The city SHALL be a lattice of axis-aligned cells addressed by integer coordinates (x, y, z) with
y pointing up. Cells have a configurable size, 64 m on every axis by default. A cell holds at
most one block; otherwise it is open air.

#### Scenario: Cell bounds
- **WHEN** the bounds of cell (1, -2, 3) are requested with the default cell size
- **THEN** the minimum corner is (64, -128, 192) and the maximum corner is (128, -64, 256)

#### Scenario: Negative positions map to negative cells
- **WHEN** the cell containing world position (-0.5, -0.5, -0.5) is requested
- **THEN** the result is cell (-1, -1, -1)

### Requirement: Upper boundary
The city SHALL have exactly one border: its roof layer (y = R, R = 0 by default). Above the
roof there are S sky layers (S = 4 by default). No block MUST ever exist above layer R + S.

#### Scenario: Nothing above the sky layers
- **WHEN** 20000 cells with y between R + S + 1 and R + 1000 and x, z spread over ±1,000,000 are queried
- **THEN** none of them holds a block

### Requirement: Sparse sky layers
The sky layers SHALL hold only sparse floating blocks whose density decreases with height: at
most 10% of the cells of any sky layer hold a block, and each sky layer is less dense than the
one below it.

#### Scenario: Sky layers thin out upward
- **WHEN** 64 × 64 cells of each sky layer R + 1 … R + S are sampled
- **THEN** every layer has a solid fraction above 0 and at most 0.10
- **AND** each layer's solid fraction is lower than the fraction of the layer below it

### Requirement: Dense roof
The roof layer SHALL be the densest layer of the city so that the city reads as having a top
surface, pierced only by shafts and canyons.

#### Scenario: Roof is denser than the layers below
- **WHEN** 64 × 64 cells of layer R and of layer R - 10 are sampled
- **THEN** the roof's solid fraction is at least 0.70 and higher than that of layer R - 10

### Requirement: Unbounded below and sideways
The city SHALL continue without end downward and in every horizontal direction, across the
full 32-bit signed range of cell coordinates, with the same statistical character everywhere
below the roof.

#### Scenario: Far regions are as dense as near ones
- **WHEN** the solid fraction of 64 × 64 cells is measured at layer R - 20 near the origin, at layer -10,000,000, and around x = 100,000,000, z = -100,000,000
- **THEN** every far measurement is within 0.08 of the near one

### Requirement: Vertical shafts
Some district columns (8 × 8 cells in x and z) SHALL contain a vertical shaft 2–3 cells wide that
runs straight from the sky layers down without end. Shaft cells never hold a block. With the
default configuration about 25% of district columns contain a shaft.

#### Scenario: A shaft runs without end
- **WHEN** cell (x, R, z) lies inside a shaft
- **THEN** cells (x, y, z) for y = R + S and for every 37th layer from R down to R - 5000 also lie inside the shaft and hold no block

#### Scenario: Shaft frequency
- **WHEN** 400 district columns are examined with the default configuration
- **THEN** between 15% and 35% of them contain a shaft

### Requirement: Horizontal canyons
Some district rows SHALL contain a horizontal canyon running without end along the X axis, and
some along the Z axis, each 2–3 cells wide and 1–2 cells tall. Canyon cells never hold a block.
Horizontal canyons exist only at or below the roof layer.

#### Scenario: An X canyon runs without end
- **WHEN** cell c lies inside a canyon running along X
- **THEN** cell c shifted by any of ±1, ±8, ±1000 and ±10,000,000 cells along X also lies inside that canyon

#### Scenario: A Z canyon runs without end
- **WHEN** cell c lies inside a canyon running along Z
- **THEN** cell c shifted by any of ±1, ±8, ±1000 and ±10,000,000 cells along Z also lies inside that canyon

#### Scenario: No horizontal canyons in the sky
- **WHEN** all cells of 20 × 20 district columns in the sky layers are examined
- **THEN** none of them lies inside a horizontal canyon

### Requirement: Plazas
Some districts below the sky SHALL contain a plaza: an open box of 1–3 cells per axis with no
blocks, giving local open space. With the default configuration about 35% of districts contain one.

#### Scenario: Plaza frequency and emptiness
- **WHEN** 400 districts below the roof are examined with the default configuration
- **THEN** between 20% and 50% of them contain a plaza
- **AND** no plaza cell holds a block

### Requirement: Block density
Below the roof, a cell that lies in no shaft, canyon or plaza SHALL hold a block with the
configured probability (0.62 by default).

#### Scenario: Density of uncarved cells
- **WHEN** 10000 uncarved cells in layers R - 1 to R - 50 are sampled with the default configuration
- **THEN** between 57% and 67% of them hold a block

### Requirement: Block geometry
Every block SHALL be an axis-aligned box inside its cell, 55%–85% of the cell size per axis,
containing the cell centre and keeping at least 4 m clearance to every cell face, so that any
two blocks are at least 8 m apart.

#### Scenario: Blocks stay inside their cells
- **WHEN** 2000 blocks are examined with the default configuration
- **THEN** every block box lies within its cell shrunk by 4 m on every side
- **AND** every block box contains its cell centre

#### Scenario: Block sizes vary
- **WHEN** 2000 blocks are examined
- **THEN** their widths along x take at least 50 distinct values between 55% and 85% of the cell width

### Requirement: Chunk generation
Cells SHALL be grouped into chunks of 4 × 4 × 4 cells. Generating a chunk MUST yield exactly the
blocks of its cells, and the result MUST equal querying each cell individually.

#### Scenario: Chunk content equals per-cell queries
- **WHEN** chunk (-2, -1, 3) is generated
- **THEN** the set of blocks it contains equals the set of solid cells among its 64 cells, with identical block data

#### Scenario: Chunks above the city are empty
- **WHEN** a chunk lying entirely above layer R + S is generated
- **THEN** it contains no blocks and no bridges

### Requirement: Floor grid
The bottom and top of every block SHALL lie on the world-wide 4 m floor grid (absolute heights
that are whole multiples of 4 m), so that every block holds a whole number of floors, between 9
and 13.

#### Scenario: Blocks on the floor grid
- **WHEN** 2000 blocks are examined
- **THEN** the absolute heights of each block's bottom and top are whole multiples of 4 m within 1 mm
- **AND** each block is between 36 m and 52 m tall
