# world-streaming Specification

## Purpose
Keeps the part of the infinite city around the player loaded — and only that part — so the city
can be explored endlessly with bounded memory and steady frame times.

## Requirements

### Requirement: Streaming region
The game SHALL keep loaded every chunk whose offset from the focus chunk (dx, dy, dz) satisfies
(dx/H)² + (dy/V)² + (dz/H)² ≤ 1, with H = 4 and V = 3 chunks by default.

#### Scenario: Chunks inside and outside the region
- **WHEN** the focus chunk is (0, -2, 0)
- **THEN** chunks (0, -2, 0), (4, -2, 0), (-4, -2, 0) and (0, -5, 0) are in the region
- **AND** chunks (5, -2, 0), (0, -6, 0) and (3, -4, 3) are not

### Requirement: Nothing is loaded above the city
Chunks that lie entirely above the highest sky layer SHALL never be loaded, wherever the focus is.

#### Scenario: Focus above the city
- **WHEN** the focus chunk is (0, 3, 0) with the default city configuration
- **THEN** every chunk in the region has a chunk y of at most 1

### Requirement: Nearest chunks first
Chunks SHALL be loaded in order of increasing normalised distance from the focus chunk, starting
with the focus chunk itself.

#### Scenario: Load order
- **WHEN** the load order for focus chunk (2, -1, -3) is requested
- **THEN** the first chunk is (2, -1, -3)
- **AND** the normalised distance never decreases along the order

### Requirement: Per-frame budget
At most 4 chunks (configurable) SHALL be generated per update so that a frame never stalls on
generation.

#### Scenario: First update loads the four nearest chunks
- **WHEN** streaming starts with nothing loaded and performs one update
- **THEN** exactly 4 chunks are loaded and they are the first 4 chunks of the load order

#### Scenario: Region fills up over updates
- **WHEN** the focus stays still and updates continue
- **THEN** after enough updates every chunk of the region is loaded and further updates load nothing

### Requirement: Unloading with hysteresis
A loaded chunk SHALL be unloaded only once it lies outside the region enlarged by one chunk on
every axis (radii H + 1 and V + 1), so moving back and forth across a chunk border does not
reload chunks.

#### Scenario: Small moves keep chunks
- **WHEN** the region around focus (0, -2, 0) is fully loaded and the focus moves to (1, -2, 0)
- **THEN** chunk (-4, -2, 0) stays loaded

#### Scenario: Large moves release chunks
- **WHEN** the region around focus (0, -2, 0) is fully loaded and the focus moves to (2, -2, 0)
- **THEN** chunk (-4, -2, 0) is unloaded
