## ADDED Requirements

### Requirement: Game clock
The game SHALL keep a clock of whole game minutes since year 0, with 365 days per year, 24 hours
per day and 7 weekdays. A new game starts in year 517, day 1, at 07:00. By default one game day
lasts 48 real minutes (half a game minute per real second).

#### Scenario: Calendar fields
- **WHEN** the clock stands at year 517, day 1, 07:00 and 1,000 game minutes pass
- **THEN** it reads year 517, day 1, 23:40
- **AND** after 30 more minutes it reads day 2, 00:10 with the next weekday

#### Scenario: Default speed
- **WHEN** the clock advances by 60 real seconds at the default speed
- **THEN** 30 game minutes have passed

### Requirement: The Light's day and night
The Light SHALL be fully bright from 07:00 to 21:00, dark from 23:00 to 05:00, and fade smoothly in
between. The sun's energy, the sky's haze and the fog's sunlit haze SHALL be scaled by the Light's
brightness.

#### Scenario: Brightness over a day
- **WHEN** the brightness is read at 12:00, 02:00, 22:00 and 06:00
- **THEN** it is 1 at noon, 0 at 02:00, and strictly between 0 and 1 at 22:00 and 06:00

#### Scenario: The sun follows the clock
- **WHEN** the main scene's clock is set to 02:00 and the world updates
- **THEN** the sun's energy is 0, and at 12:00 it is the full atmosphere energy
