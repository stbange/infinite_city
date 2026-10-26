# city-rendering Specification

## Purpose
Shows the generated city: floating blocks and bridges in the right places, a single light
source above the roof, and an atmosphere that makes depth readable.

## Requirements

### Requirement: Blocks are drawn where they are generated
Every block of a loaded chunk SHALL be drawn as a box with the block's size, centred at the
block's position relative to the floating origin, tinted with its function's colour.

#### Scenario: One box per block
- **WHEN** a chunk with N blocks is loaded
- **THEN** exactly N boxes are drawn for it
- **AND** each box's centre equals the scene position of its cell centre plus the block offset within 1 mm, and its size equals the block size within 1 mm

#### Scenario: Function colours
- **WHEN** a hospital block and a farm block are drawn
- **THEN** each box is tinted with its function's colour

### Requirement: Bridges are drawn as decks
Every bridge owned by a loaded chunk SHALL be drawn as a deck of the bridge's width running from
its start to its end point.

#### Scenario: One deck per bridge
- **WHEN** a chunk owning M bridges is loaded
- **THEN** exactly M decks are drawn for it
- **AND** each deck's length equals the bridge length and its width equals the bridge width within 1 mm

### Requirement: Light source above the roof
The scene SHALL be lit by a single light source located above the roof: a directional light
shining down onto the city, and a bright star in the sky above.

#### Scenario: Light shines from above
- **WHEN** the main scene is loaded
- **THEN** it contains exactly one directional light
- **AND** the light's direction points downward with a vertical component of at least 0.7

### Requirement: Depth atmosphere
The atmosphere SHALL be dark and foggy and get darker the deeper the camera is below the roof,
without ever becoming completely black. Below the roof layer the fog SHALL limit visibility to at
most 400 m (fog density of at least 0.0075 per metre); above the roof it is thinner.

#### Scenario: Deeper is darker
- **WHEN** the atmosphere is evaluated at depths of 0, 50 and 500 layers below the roof
- **THEN** the fog brightness strictly decreases from 0 to 50 to 500 layers
- **AND** the fog brightness at 500 layers is above zero

#### Scenario: Above the roof is brightest
- **WHEN** the atmosphere is evaluated 3 layers above the roof
- **THEN** the fog brightness is at least the brightness at the roof

#### Scenario: Dense fog below the roof
- **WHEN** the fog density is evaluated at depths of 1, 5, 50 and 10,000 layers
- **THEN** it is at least 0.0075 per metre in each case

#### Scenario: Thinner fog above the roof
- **WHEN** the fog density is evaluated 3 layers above the roof
- **THEN** it is less than half the density 1 layer below the roof

### Requirement: Bridges are drawn with railings
Every drawn bridge deck SHALL have a railing 1.1 m high along each of its two edges, as long as
the deck.

#### Scenario: Two railings per deck
- **WHEN** a chunk owning M bridges is loaded
- **THEN** exactly 2 × M railings are drawn, each as long as its deck and 1.1 m high
