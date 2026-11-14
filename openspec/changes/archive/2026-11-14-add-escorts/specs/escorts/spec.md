## ADDED Requirements

### Requirement: Escorts
With a gold licence some orders SHALL be people who travel with the courier, following over the
navigation graph, and the delivery SHALL only count with them at the door.

#### Scenario: Escorts at gold
- **WHEN** four days of a gold courier's orders are listed
- **THEN** some are people (tier 4)

#### Scenario: An escort must keep up
- **WHEN** the courier reaches the door while the passenger is far behind, then waits
- **THEN** the delivery is refused with a message, and the passenger walks up
