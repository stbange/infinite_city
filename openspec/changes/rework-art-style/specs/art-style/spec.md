## ADDED Requirements

### Requirement: A restrained palette
The city SHALL be drawn mostly in greys and darkness: fog, edge strips, rails and facades nearly
grey; lamps and corridor lights warm or cool white; accents such as signs, furniture and faction
colours keeping only part of their saturation.

#### Scenario: Greys and whites
- **WHEN** the palette's fog, strip, facade, lamp and corridor colours are examined
- **THEN** fog, strips and facades are nearly grey and every lamp and corridor light is a pale warm or cool white

#### Scenario: Muted accents
- **WHEN** a vivid sign colour is muted
- **THEN** it keeps its hue but loses most of its saturation, and drawn signs use the muted colour

### Requirement: Shadows
The sun SHALL cast shadows across the roof; blocks, bridges and interiors SHALL cast shadows; the
lights nearest the player SHALL cast shadows.

#### Scenario: Things cast shadows
- **WHEN** the main scene, a chunk and the light pool are examined
- **THEN** the sun casts shadows, solid chunk geometry casts shadows while glowing signs do not, and the first lights of the pool cast shadows

### Requirement: Colour grade
The view SHALL be desaturated, with more contrast and softer glow, as set by the palette.

#### Scenario: The grade
- **WHEN** the main scene's environment is examined
- **THEN** it desaturates, adds contrast and darkens as the palette says
