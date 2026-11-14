# rival-couriers Specification

## Purpose
Other couriers who take orders left waiting at the counter.

## Requirements

### Requirement: Rival couriers
About half of the counter's orders SHALL be taken by rival couriers at a fixed minute of the hour
if the courier has not taken them first.

#### Scenario: Rivals take orders
- **WHEN** two days of orders are examined
- **THEN** about half have a rival minute between :10 and :59, the same every time
