# encounters Specification

## Purpose
What happens when a courier with cargo crosses a gang's bridge: tolls, shakedowns, talking and chases.

## Requirements

### Requirement: Encounters on claimed bridges
Stepping onto a claimed bridge with cargo SHALL roll an encounter once per bridge and game hour —
pass, toll or shakedown, likelier with heat — and never without cargo.

#### Scenario: A toll on the bridge
- **WHEN** the courier with cargo walks onto a claimed bridge whose roll is a toll
- **THEN** the gang blocks the way and asks for the toll, and paying takes it from the wallet

#### Scenario: No cargo, no encounter
- **WHEN** the courier walks onto a claimed bridge carrying nothing
- **THEN** nothing happens

#### Scenario: Rolls depend on cargo and heat
- **WHEN** the rolls of many bridges are computed with cargo, with and without heat
- **THEN** both tolls and passes occur, more encounters occur with heat, and none occur without cargo

### Requirement: Talking and running
The courier SHALL be able to talk (a chance that shrinks with heat; failing doubles the price) or
run; running or leaving the bridge starts a chase that ends in escape (40 m away, or 30 seconds)
with more heat, or capture, which loses the cargo and credits.

#### Scenario: Escaping a chase
- **WHEN** the courier refuses and gets 40 m away from the gang
- **THEN** the chase ends, the cargo is kept and the heat with that gang is higher

#### Scenario: Caught
- **WHEN** the courier refuses and the gang reaches them
- **THEN** the carried cargo is lost and credits are taken
