## ADDED Requirements

### Requirement: Bridge claims
Bridges SHALL be claimed by gangs that exist today: every bridge of a district a gang owns is
claimed by that gang, and some bridges next to a gang's home district are claimed by it; claims
are deterministic per seed.

#### Scenario: Claims follow the history
- **WHEN** the bridges of the districts around the start are examined
- **THEN** some are claimed, each by a gang of the bridge's Reach that exists today, and every bridge in a gang-owned district is claimed by its owner

#### Scenario: Deterministic claims
- **WHEN** the claims of the same bridges are computed by a new generator
- **THEN** they are the same

### Requirement: Tolls and heat
The toll SHALL grow with the cargo carried and with the courier's heat with that gang; heat SHALL
halve every two game hours.

#### Scenario: Toll grows with heat and cargo
- **WHEN** tolls are computed for more cargo or more heat
- **THEN** they are higher

#### Scenario: Heat cools down
- **WHEN** heat of 1.0 is read two game hours later
- **THEN** it is 0.5
