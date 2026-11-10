## ADDED Requirements

### Requirement: Saves keep the changed world
Saves SHALL be version 2 and hold the event log beside the player, clock, courier, story and
encounter state; version 1 saves SHALL still load; F5 SHALL save and F9 load the quick slot.

#### Scenario: Version 2 with events
- **WHEN** a session with events is saved and loaded
- **THEN** the save says version 2 and the events come back

#### Scenario: Older saves still load
- **WHEN** a version 1 save without events is loaded
- **THEN** it loads and the world has no events
