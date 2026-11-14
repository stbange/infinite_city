# blackouts Specification

## Purpose
Districts going dark for a night, the dark windows that show it, and the courier's battery lamp.

## Requirements

### Requirement: Blackouts
Districts in the live area SHALL now and then go dark for a night, from 19:00 to 06:00: their
windows unlit, the HUD saying so, and the event kept in the log.

#### Scenario: Blackout nights
- **WHEN** a blackout is recorded for a district and day
- **THEN** it is dark from that evening until the next morning, and its neighbours are not

#### Scenario: Blackouts in the live area
- **WHEN** a district is ticked for sixty days
- **THEN** it goes dark on a few of them

#### Scenario: The lights go out
- **WHEN** the courier's district has a blackout at night
- **THEN** its windows are dark, and they light again in the morning

### Requirement: The lamp
The courier SHALL have a lamp that drains a battery while on and recharges at the patron's counter.

#### Scenario: The lamp runs on a battery
- **WHEN** the lamp burns for five and then seven more game hours, and the courier visits the counter
- **THEN** the battery is half, then empty and the lamp off, then full again
