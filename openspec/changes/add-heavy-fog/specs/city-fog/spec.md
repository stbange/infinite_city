## ADDED Requirements

### Requirement: Fog by height
Fog density SHALL be evaluated per point along each view ray from the point's height. The sunlit
roof layer holds only a light haze (at most a fifth of the heavy density); the heavy fog — a fog
sea — fills everything from half a layer below the roof layer's bottom down, blending into the haze
over one layer around that bottom, where sunlight fades out. Above the roof surface the haze falls
by a factor e every half layer, so the light source stays visible from the roof.

#### Scenario: Light haze in the roof layer
- **WHEN** the density is evaluated at the roof surface and half a layer below it, with a density of 0.02 per metre below the roof layer
- **THEN** it is at most 0.004 per metre in both places

#### Scenario: Fog sea
- **WHEN** the density is evaluated 1.5 and 20 layers below the roof surface, with a density of 0.02 per metre below the roof layer
- **THEN** it is 0.02 per metre in both places

#### Scenario: Clearing above the roof
- **WHEN** the density is evaluated 3 layers above the roof surface
- **THEN** it is less than 5% of the density at the roof surface

#### Scenario: The shader follows the same rule
- **WHEN** the main scene runs with the player at its starting point
- **THEN** the fog shader's density below the roof layer equals the density for the player's depth, its haze density, clearing rate, fog sea depth and band and its layer height equal the atmosphere's, and its roof heights are the scene heights of the roof layer's bottom and top

### Requirement: Sunlit haze in the uppermost layer
Fog in and above the roof layer SHALL glow with the light source; fog deeper down SHALL be lit
only by the city (dark violet).

#### Scenario: Haze colour
- **WHEN** the main scene runs
- **THEN** the fog shader's sun haze colour and fade distance equal the atmosphere's, and its colours below and above the roof equal the atmosphere's fog colours for the player's depth

### Requirement: Drifting fog banks
The fog density SHALL vary in banks that drift with a slow wind. The banks SHALL be anchored to
absolute world positions: moving the floating origin does not move them.

#### Scenario: Banks and wind
- **WHEN** the fog material is examined
- **THEN** its bank strength and wind speed are above zero

#### Scenario: Banks stay put when the origin moves
- **WHEN** the floating origin is placed at chunks (0, 0, 0), (3, -7, 12) and (5, -2500000, -9)
- **THEN** for each placement, the fog's noise offset plus the scene position of a fixed absolute point is the same modulo the noise period of 1024 m

### Requirement: Clear air indoors
There SHALL be no fog inside entered blocks.

#### Scenario: Clear inside an entered block
- **WHEN** the player stands inside a block whose interior is ready
- **THEN** the fog has a clear box covering that block from the bottom of its lowest slab to its roof, in scene coordinates

### Requirement: One fog for every camera
The fog SHALL be drawn as a full-screen pass on its own visual layer. The main camera draws it
while the player is outside pocket spaces; inside a pocket space it does not. The portal camera
draws it when it shows the city from inside a pocket space, and not when it shows a pocket space.
The built-in environment fog SHALL be off, so no surface is fogged twice.

#### Scenario: Outside
- **WHEN** the player stands in the city near a magic doorway
- **THEN** the main camera draws the fog layer and the portal camera does not

#### Scenario: Inside a pocket space
- **WHEN** the player has stepped through a magic doorway into its pocket space
- **THEN** the main camera does not draw the fog layer and the portal camera draws the fog, city and interior layers

#### Scenario: No double fog
- **WHEN** the main scene runs
- **THEN** the environment's built-in fog is disabled and the fog quad hangs in front of the player's camera on the fog layer
