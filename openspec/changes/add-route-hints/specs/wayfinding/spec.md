## ADDED Requirements

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
