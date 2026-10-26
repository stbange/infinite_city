# Spec Delta

## MODIFIED Requirements

### Requirement: Bridge geometry
A bridge deck SHALL be 6 m wide and run straight along its axis from the facing side of one
block to the facing side of the other, along the line through both cell centres. Its walking
surface lies on the 4 m floor grid, with at least one full floor (4 m) of each block above it.

#### Scenario: Deck spans face to face
- **WHEN** 500 bridges are examined
- **THEN** each deck starts on the facing side of its first block and ends on the facing side of its second block, within 1 cm

#### Scenario: Deck lies within both blocks
- **WHEN** 500 bridges are examined
- **THEN** each deck's full width lies within the lateral extent of both blocks
- **AND** each deck's height lies within the vertical extent of both blocks

#### Scenario: Deck on the cell centre line and the floor grid
- **WHEN** 500 bridges are examined
- **THEN** each deck's centre line is on the line through both cell centres within 1 mm
- **AND** the absolute height of each deck is a whole multiple of 4 m within 1 mm
- **AND** each block reaches at least 4 m above the deck
