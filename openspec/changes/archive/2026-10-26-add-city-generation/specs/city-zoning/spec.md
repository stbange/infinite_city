# Spec Delta

## Purpose

Decides what every block in the city is used for, so the city works like a real city: people
live, grow food, shop and work in it, and every neighbourhood has the services it needs.

## ADDED Requirements

### Requirement: Block functions
Every block SHALL have exactly one function: housing, farm, market, office, industry, park,
hospital, fire station, security station, school, power plant, water works or transit hub.
Open-air cells have no function.

#### Scenario: Every block has one function
- **WHEN** 5000 cells below the roof are queried with seed 1337
- **THEN** every solid cell reports exactly one function from the list
- **AND** every open-air cell reports no function

### Requirement: Districts
The city SHALL be divided into districts of 8 × 8 × 8 cells. The roof layer is the top layer of
the topmost row of districts; the sky layers belong to the district row above it.

#### Scenario: District membership
- **WHEN** the districts of cells (0, R, 0), (7, R - 7, 7), (0, R - 8, 0), (-1, R, 0) and (0, R + 1, 0) are compared
- **THEN** (0, R, 0) and (7, R - 7, 7) share a district
- **AND** (0, R - 8, 0), (-1, R, 0) and (0, R + 1, 0) are each in a different district from (0, R, 0)

### Requirement: Essential services in every district
Every district at or below the roof that contains at least 7 blocks SHALL contain exactly one
hospital, one fire station, one security station, one school, one power plant, one water works
and one transit hub. Essential services never appear anywhere else.

#### Scenario: Services in ordinary districts
- **WHEN** every district with dx and dz in -3…3 and dy in {-1, -2, -50} is examined with seed 1337
- **THEN** each contains exactly one block of each of the seven essential services

#### Scenario: Services in very sparse districts
- **WHEN** the block density and roof density are both configured to 0.03 and a district below the roof has at least 7 blocks
- **THEN** it still contains exactly one block of each of the seven essential services

#### Scenario: No services in the sky
- **WHEN** all sky-layer blocks of 10 × 10 district columns are examined
- **THEN** none of them is an essential service

### Requirement: Depth-dependent mix
Blocks that are not essential services SHALL follow a mix that depends on depth below the roof:
near the roof (depth 0–23 layers) markets and offices are common; in the deep (depth 96 layers
and more) farms and industry dominate. Sky blocks are only housing, parks or markets.

#### Scenario: Farms and industry dominate the deep
- **WHEN** 3000 non-service blocks within depth 0–23 and 3000 non-service blocks at depth 96 or more are sampled
- **THEN** the share of farms plus industry in the deep sample is at least twice its share near the roof
- **AND** the share of markets plus offices near the roof is at least twice its share in the deep sample

#### Scenario: Sky blocks are homes, parks or markets
- **WHEN** all sky-layer blocks of 20 × 20 district columns are examined
- **THEN** every one of them is housing, a park or a market
