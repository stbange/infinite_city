# wayfinding Specification

## Purpose
Helping the courier find the way without lifting the fog: route hints, gang-aware routes and chasers that follow corridors and stairs.

## Requirements

### Requirement: Route hints
The courier SHALL see lights along the next 30 m of the walking route to the next door, replanned
from wherever they stand, which can be turned off; the scanner SHALL light the whole route for a
while.

#### Scenario: Hints lead the way
- **WHEN** the courier stands in a corridor with a door to reach, then walks elsewhere, then turns hints off
- **THEN** lights show only the next stretch of the route, the route starts again from the new place, and the lights go out

#### Scenario: The scanner shows the whole way
- **WHEN** the courier scans while the route is longer than the hint stretch
- **THEN** more of the route is lit

### Requirement: Gang-aware routes
Routes SHALL be able to avoid bridges held by gangs: crossing one costs extra, so a detour is taken
when there is one and the extra cost is paid when there is none.

#### Scenario: Gang bridges cost more
- **WHEN** a route across a bridge is found again with that bridge penalised
- **THEN** either a longer detour avoids it, or the route still crosses it at the penalty's cost

### Requirement: Chases on the graph
Chasing gang members SHALL follow paths over the navigation graph to the courier.

#### Scenario: Chasers follow the graph
- **WHEN** the courier runs off the bridge into a block and up a floor
- **THEN** every chaser has a path through the block and closes in along it
