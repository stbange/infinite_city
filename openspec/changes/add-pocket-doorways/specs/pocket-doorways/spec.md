# Spec Delta

## Purpose

Decides which blocks of the city carry a magic doorway and exactly where on the block it opens,
so every visitor finds the same doorways in the same places.

## ADDED Requirements

### Requirement: Which blocks have doorways
Every transit hub SHALL carry exactly one doorway. Every other block SHALL carry one doorway with
a probability of 10% by default, decided deterministically from the seed and its cell. A block
never carries more than one doorway; open-air cells carry none.

#### Scenario: Doorway frequency
- **WHEN** 4000 blocks that are not transit hubs are examined with seed 1337
- **THEN** between 7% and 13% of them carry a doorway

#### Scenario: Transit hubs always have a doorway
- **WHEN** the transit hubs of 20 districts are examined
- **THEN** every one of them carries a doorway

#### Scenario: Same doorways every time
- **WHEN** two generators with seed 1337 query the doorways of the same 500 blocks
- **THEN** they report identical doorways

### Requirement: Doorway shape and position
A doorway SHALL be a vertical opening 4 m wide and 6 m tall lying flat on one of the four side
faces of its block, facing outward, and fitting inside that face with at least 1 m to spare on
every side.

#### Scenario: Doorways sit on a side face
- **WHEN** 500 doorways are examined
- **THEN** each doorway's plane coincides with a side face of its block within 1 cm and its facing direction is that face's outward normal
- **AND** the whole opening lies within the face with at least 1 m margin

### Requirement: Doorways meet bridges
When a block has a bridge whose deck leaves room for the doorway (deck height + 6 m + 1 m within
the block), the doorway SHALL open at the end of that bridge: on the same face, centred on the
deck, standing on the deck.

#### Scenario: Doorway at the end of a bridge
- **WHEN** a block with a doorway has a bridge with room above its deck
- **THEN** the doorway is on the face where that bridge meets the block, its bottom is at the deck height and its centre is on the deck's centre line, all within 1 cm

### Requirement: Doorways per chunk
Generating the doorways of a chunk SHALL return exactly the doorways of the blocks in that chunk.

#### Scenario: Chunk doorways equal per-block queries
- **WHEN** the doorways of chunk (1, -1, 2) are generated
- **THEN** they equal the doorways reported for each block of that chunk individually
