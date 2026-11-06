## ADDED Requirements

### Requirement: Major traffic lanes
On each axis, a cell boundary (the plane between cell index b − 1 and b) SHALL be a major traffic
lane with the configured probability (0.16 by default), decided from the seed, the axis and the
boundary index alone. A lane is therefore a plane of open space through the whole city: blocks on
both sides keep 16–18 m back from it (exactly 16 m vertically), so no block comes within 32 m
across it.

#### Scenario: Lane frequency
- **WHEN** boundaries −300 … 299 of each axis are examined with the default configuration
- **THEN** between 10% and 25% of them are lanes on every axis

#### Scenario: A lane runs without end
- **WHEN** the first lane boundary at or above index 0 on the x axis is taken and 2000 blocks are sampled in the cells on both sides of it, with y and z spread over ±100,000
- **THEN** every one of those blocks keeps at least 16 m from the lane plane

#### Scenario: Same lanes for every generator
- **WHEN** two generators with the same seed are asked about boundaries −1000 … 999 of each axis
- **THEN** they agree on every boundary, and a different seed disagrees on at least one

## MODIFIED Requirements

### Requirement: Block density
Below the roof, a cell that lies in no shaft, canyon or plaza SHALL hold a block with the
configured probability (0.9 by default).

#### Scenario: Density of uncarved cells
- **WHEN** 10000 uncarved cells in layers R - 1 to R - 50 are sampled with the default configuration
- **THEN** between 86% and 94% of them hold a block

### Requirement: Dense roof
The roof layer SHALL be the densest layer of the city (0.96 of its uncarved cells by default) so
that the city reads as having a top surface, pierced only by shafts and canyons.

#### Scenario: Roof is denser than the layers below
- **WHEN** 64 × 64 cells of layer R and of layer R - 10 are sampled
- **THEN** the roof's solid fraction is at least 0.70 and higher than that of layer R - 10

### Requirement: Block geometry
Every block SHALL be an axis-aligned box inside its cell containing the cell centre. Each of its
faces is set back from the cell face behind it: horizontally by 2–6 m across an ordinary street;
vertically by 0 or 4 m at the bottom and 4 or 8 m at the top; and by the lane setback across a
major traffic lane. Neighbouring blocks are therefore 4–12 m apart across a street.

#### Scenario: Blocks stay inside their cells
- **WHEN** 2000 blocks are examined with the default configuration
- **THEN** every block box lies within its cell and contains its cell centre
- **AND** every face is set back by the street or lane setback for the boundary behind it

#### Scenario: Narrow streets
- **WHEN** 2000 pairs of neighbouring blocks along x and z across ordinary boundaries are examined
- **THEN** every gap is between 4 m and 12 m and the average gap is below 10 m

#### Scenario: Block sizes vary
- **WHEN** 2000 blocks are examined
- **THEN** their widths along x take at least 50 distinct values

### Requirement: Floor grid
The bottom and top of every block SHALL lie on the world-wide 4 m floor grid (absolute heights
that are whole multiples of 4 m), so that every block holds a whole number of floors, between 8
and 15.

#### Scenario: Blocks on the floor grid
- **WHEN** 2000 blocks are examined
- **THEN** the absolute heights of each block's bottom and top are whole multiples of 4 m within 1 mm
- **AND** each block is between 32 m and 60 m tall
