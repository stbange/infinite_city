# city-navigation Specification

## Purpose
Walking routes over the city: navigation graphs of blocks built from their floor plans, joined by bridges, and bounded shortest-route searches between units, doors and entrances.

## Requirements

### Requirement: Block navigation
Every block SHALL have a navigation graph with a node inside every unit on every floor, a node at
every unit door's front, a stair landing on every floor joined to the floors above and below, and
an entrance node where each bridge meets the block, all joined through the corridors.

#### Scenario: Every unit reachable from every entrance
- **WHEN** the graphs of 200 sampled blocks with bridges are searched from each entrance
- **THEN** the node inside every unit of every floor is reached

#### Scenario: Stairs join the floors
- **WHEN** the route from a unit on floor 0 to the same unit on floor 3 is found within a block
- **THEN** it passes the stair landings of floors 0 to 3 and is longer than three stair flights

### Requirement: Routes over bridges
A route between two places SHALL be found over block graphs joined by bridges, as the shortest
path with its points and length, and SHALL be the same whichever order the blocks were visited in.

#### Scenario: Shortest route on a known plan
- **WHEN** the route between two units on the same corridor of the same floor is found
- **THEN** its length equals the walk out of the first unit, along the corridor and into the second

#### Scenario: Route across a bridge
- **WHEN** the route from a unit of a block to a unit of the block across one of its bridges is found
- **THEN** it passes both entrances of that bridge and its length is at least the bridge's length

#### Scenario: Bounded search
- **WHEN** a route is asked between places farther apart than the search box allows
- **THEN** no route is returned and the search stops within its node budget
