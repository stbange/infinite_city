# Spec Delta

## Purpose

Keeps rendering and movement precise everywhere in an unbounded city by expressing every scene
position relative to an integer origin that follows the camera.

## ADDED Requirements

### Requirement: Integer origin
Every position in the scene SHALL be relative to an origin chunk given by integer coordinates.
The absolute location of a scene position is the origin chunk's corner plus the position.

#### Scenario: Absolute cell of a scene position
- **WHEN** the origin chunk is (2, -3, 1) with 4-cell chunks of 64 m cells and a scene position is (10, 20, 30)
- **THEN** its absolute cell is (8, -12, 4) and its offset inside that cell is (10, 20, 30)

#### Scenario: Scene position of a far cell
- **WHEN** the origin chunk is (0, -2,500,000, 0) and the centre of cell (1, -10,000,000, 2) is requested
- **THEN** its scene position is exactly (96, 32, 160)

### Requirement: Rebasing
When the camera is more than 512 m from the scene origin along any axis, the origin SHALL move
to the chunk containing the camera, and all world content SHALL be shifted by the same whole
number of chunks so the camera ends up within one chunk of the origin.

#### Scenario: Camera far from origin
- **WHEN** the camera's scene position is (600, 0, 0) with 256 m chunks
- **THEN** the origin chunk moves by (2, 0, 0) and the camera's scene position becomes (88, 0, 0)

#### Scenario: Camera near origin
- **WHEN** the camera's scene position is (-10, -500, 300)
- **THEN** the origin does not move

### Requirement: Rebasing preserves the world
Rebasing SHALL NOT change the absolute location of anything in the world: chunks, the camera and
any other world content keep their absolute positions to within 1 mm.

#### Scenario: Markers keep their place
- **WHEN** world content at several scene positions is shifted by a rebase of (3, -1, 2) chunks
- **THEN** the absolute location of every piece of content is unchanged within 1 mm

### Requirement: Precision independent of distance
Positions SHALL stay accurate to 1 cm however far the player travels.

#### Scenario: Long flight
- **WHEN** the camera flies 100 km along +X in 10 m steps with rebasing
- **THEN** its scene position never exceeds 522 m from the origin along any axis
- **AND** its absolute position afterwards is 100,000 m from the start within 1 cm
