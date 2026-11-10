## ADDED Requirements

### Requirement: Gang tags at turf edges
A block SHALL carry gang tags exactly when its district is owned by a gang and its cell lies on the
district's edge towards a neighbouring district with a different owner. It then carries 1–3 tags:
small signs (at most 2.5 m by 1.5 m) in the gang's colour on its side faces.

#### Scenario: Tags mark turf edges
- **WHEN** the blocks of 6 Reaches are examined
- **THEN** every block with tags is on such an edge, every tag has the owning gang's colour and is at most 2.5 × 1.5 m
- **AND** at least one tagged block is found, and every edge block has 1–3 tags

### Requirement: Memorials
Every district that suffered a raid or blackout SHALL have one memorial: a steady white sign on the
block of the district's memorial cell, when that cell holds a block. Other districts have none.

#### Scenario: Memorials where blood was spilled
- **WHEN** the districts of 6 Reaches are examined
- **THEN** each damaged district whose memorial cell holds a block has exactly one memorial sign on it, and no other block of those Reaches has one

### Requirement: Ruins
In districts that suffered a raid or blackout, a block SHALL be ruined with probability 0.25 (from
the seed and its cell); elsewhere no block is ruined. Ruined blocks are drawn with almost no lit
windows and a darker facade.

#### Scenario: Share of ruins
- **WHEN** 3,000 blocks of damaged districts and 1,000 of undamaged districts are examined
- **THEN** between 18% and 32% of the first are ruined and none of the second

#### Scenario: Ruins are drawn
- **WHEN** a chunk containing a ruined block is built
- **THEN** that block's instance data carries the ruin flag and other blocks do not

### Requirement: Turf read-out
The HUD SHALL name the owner of the player's district and the Reach.

#### Scenario: Read-out names the turf
- **WHEN** the main scene's HUD refreshes
- **THEN** it contains "Turf: " followed by the name of the district's owner, and the Reach's name

### Requirement: Debug timeline
F3 SHALL toggle a panel with the current Reach's name, its living factions and its latest events.

#### Scenario: Timeline panel
- **WHEN** the debug panel is shown in the main scene
- **THEN** it contains the Reach's name and the text of its latest event
