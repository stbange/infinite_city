## ADDED Requirements

### Requirement: Event log and overlays
Every change to the world SHALL be an event in an append-only log, and queries SHALL read the
baseline and then the events: bridge claims, food prices and the residents of a flat.

#### Scenario: Replay
- **WHEN** the same log is applied to the same seed twice, from a saved copy
- **THEN** every query over a test region gives the same answers

#### Scenario: A move in both directions
- **WHEN** a resident moves to another flat
- **THEN** they are among the new flat's residents and no longer among the old flat's

#### Scenario: Claims and prices from events
- **WHEN** a bridge is taken by a gang and a district's food price changes
- **THEN** the bridge's claim and the district's price follow the events
