## ADDED Requirements

### Requirement: Version 3 saves
Saves SHALL be version 3 with the courier state as its own part; version 2 saves, which kept it in
the courier part, SHALL still load.

#### Scenario: Version 2 courier parts still load
- **WHEN** a courier part in the version 2 layout is loaded
- **THEN** deliveries, credits, standing, licence and tools come back
