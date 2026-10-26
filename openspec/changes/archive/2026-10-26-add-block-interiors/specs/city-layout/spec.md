# Spec Delta

## ADDED Requirements

### Requirement: Floor grid
The bottom and top of every block SHALL lie on the world-wide 4 m floor grid (absolute heights
that are whole multiples of 4 m), so that every block holds a whole number of floors, between 9
and 13.

#### Scenario: Blocks on the floor grid
- **WHEN** 2000 blocks are examined
- **THEN** the absolute heights of each block's bottom and top are whole multiples of 4 m within 1 mm
- **AND** each block is between 36 m and 52 m tall
