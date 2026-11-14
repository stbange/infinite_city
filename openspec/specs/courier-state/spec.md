# courier-state Specification

## Purpose
What the courier owns and is — wallet, standing, licence and tools — kept and saved in one place.

## Requirements

### Requirement: Courier state
The courier's wallet, standing, licence and tools SHALL live in one courier state with the rules
that change them, saved as its own part of the session.

#### Scenario: Courier state is saved
- **WHEN** the courier state with standing, a silver licence and flares is saved and loaded
- **THEN** standing, licence and flares come back
