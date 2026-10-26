# Spec Delta

## Purpose

Decides where light comes from in the city: daylight on the uppermost layer only, and below it
nothing but artificial light — lit windows, neon signs and bridge lamps — for a dark, moody city.

## ADDED Requirements

### Requirement: Sunlight only on the uppermost layer
Light from the light source SHALL fully reach surfaces from 16 m above the bottom of the roof
layer upward, fade out smoothly to nothing at 16 m below the bottom of the roof layer, and
be absent everywhere deeper.

#### Scenario: Sunlit roof layer
- **WHEN** the sun visibility is evaluated at the top of the roof layer, 16 m above its bottom and 3 layers above the roof
- **THEN** it is 1 in each case

#### Scenario: Dark below
- **WHEN** the sun visibility is evaluated 16 m below the bottom of the roof layer, 5 layers deeper and 10,000,000 layers deeper
- **THEN** it is 0 in each case

#### Scenario: Fade at the bottom of the roof layer
- **WHEN** the sun visibility is evaluated at the bottom of the roof layer
- **THEN** it is 0.5

### Requirement: Interiors are never sunlit
The light source SHALL only light the city's outside; building interiors and pocket spaces never
receive its light.

#### Scenario: Light layers
- **WHEN** the main scene is loaded
- **THEN** the light source affects the city's outside layer and neither the interior nor the pocket layer

### Requirement: Dark ambience
Ambient light SHALL be at most 5% of full brightness at every depth, so that unlit surfaces read
as dark.

#### Scenario: Low ambient light
- **WHEN** the ambient light is evaluated at depths of -3, 0, 1, 50 and 10,000 layers
- **THEN** it is at most 0.05 in each case

### Requirement: Neon signs
Blocks SHALL carry glowing signs on their side faces: markets 2–3, offices up to 2, other ordinary
blocks up to 1, and every essential service exactly 1 in its function's colour when it fits.
Other signs use a neon palette. About 15% of signs flicker. Signs are deterministic.

#### Scenario: Signs per function
- **WHEN** 3000 blocks are examined with seed 1337
- **THEN** no market has more than 3 signs, no office more than 2, no other ordinary block more than 1 and no service more than 1
- **AND** at least 70% of markets have 2 or more signs and at least 90% of services have exactly 1

#### Scenario: Service signs show the service colour
- **WHEN** the signs of essential services are examined
- **THEN** each one has its function's colour

#### Scenario: Some signs flicker
- **WHEN** 2000 signs are examined
- **THEN** between 8% and 22% of them flicker

#### Scenario: Same signs every time
- **WHEN** two generators with seed 1337 produce the signs of the same 300 blocks
- **THEN** the signs are identical

### Requirement: Sign placement
A sign SHALL be a flat panel 0.3 m in front of one side face of its block, lying within that face
with at least 1 m margin, outside the 8 m band on either side of the face's cell centre line
(where bridges and entrances arrive), not overlapping the block's magic doorway, and not
overlapping another sign of the same face.

#### Scenario: Signs stay clear
- **WHEN** the signs of 1000 blocks are examined
- **THEN** every sign lies within its face with 1 m margin and 0.3 m in front of it
- **AND** no sign reaches into the 8 m band around the cell centre line
- **AND** no sign overlaps its block's magic doorway (with 1 m margin) or another sign on the same face

### Requirement: Bridge lamps
Every bridge SHALL carry lamps along both edges: one every 12 m starting 2 m from the start of the
deck, with the light 3.2 m above the deck and 0.3 m inside the edge.

#### Scenario: Lamps along a bridge
- **WHEN** the lamps of 300 bridges are examined
- **THEN** each bridge has floor((length - 4) / 12) + 1 lamps on each edge, at least one per edge
- **AND** every lamp is 3.2 m above the deck, 0.3 m inside an edge and between the deck's start and end

### Requirement: Real light near the player
The game SHALL light the surroundings with real light sources placed at the nearest signs and
lamps — up to 12 at a time. The chosen set changes only when a candidate comes at least 10 m
closer than the farthest chosen one, so lights do not jump around with every step.

#### Scenario: Nearest light anchors are chosen
- **WHEN** 40 anchors surround the camera and none is chosen yet
- **THEN** the 12 nearest anchors are chosen

#### Scenario: Small moves keep the lights
- **WHEN** the camera then moves 3 m
- **THEN** the chosen set does not change

#### Scenario: Much closer anchors take over
- **WHEN** an anchor appears 1 m from the camera while every chosen anchor is more than 11 m away
- **THEN** it replaces the farthest chosen anchor
