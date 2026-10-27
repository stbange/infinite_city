## MODIFIED Requirements

### Requirement: Depth atmosphere
The atmosphere SHALL be dark and foggy and get darker the deeper the camera is below the roof,
without ever becoming completely black. From half a layer below the roof layer down the fog SHALL
be heavy — a density of at least 0.018 per metre, so less than 5% of a surface shows through after
about 170 m — and it SHALL get heavier the deeper the player is; above the roof it is thinner. How
the fog varies along each view ray is specified by `city-fog`.

#### Scenario: Deeper is darker
- **WHEN** the atmosphere is evaluated at depths of 0, 50 and 500 layers below the roof
- **THEN** the fog brightness strictly decreases from 0 to 50 to 500 layers
- **AND** the fog brightness at 500 layers is above zero

#### Scenario: Above the roof is brightest
- **WHEN** the atmosphere is evaluated 3 layers above the roof
- **THEN** the fog brightness is at least the brightness at the roof

#### Scenario: Dense fog below the roof
- **WHEN** the fog density is evaluated at depths of 1.5, 5, 50 and 10,000 layers
- **THEN** it is at least 0.018 per metre in each case

#### Scenario: Thinner fog above the roof
- **WHEN** the fog density is evaluated 3 layers above the roof
- **THEN** it is less than half the density 1 layer below the roof

#### Scenario: Heavier deeper down
- **WHEN** the fog density is evaluated at depths of 1.5 and 500 layers
- **THEN** it is higher at 500 layers
