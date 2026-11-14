# economy-tables Specification

## Purpose
The numbers that decide how the game feels, kept in one data table, checked by a scripted balance run and measured in play by session stats.

## Requirements

### Requirement: Economy table
Every number that decides pay, rent, tolls, chases, fees, prices and price drift SHALL come from
one validated data table, read when it is used.

#### Scenario: The table is valid
- **WHEN** the economy table is loaded
- **THEN** it passes its schema and has every section

#### Scenario: Rules read the table
- **WHEN** single values of the table are overridden
- **THEN** tolls, rent, shop prices and pay follow at once

### Requirement: Balance report
A scripted courier SHALL play the delivery loop over real routes and report what steady play
earns, deterministically, so the table can be tuned against the rent.

#### Scenario: A day of steady play
- **WHEN** half a game day is played by the scripted courier, twice
- **THEN** both runs earn the same, between a fifth and a half of the weekly rent, with some tips

### Requirement: Session stats
The game SHALL count orders, deliveries, earnings, tolls, rescues and delivery times for the
session and show them on F4.

#### Scenario: Session stats
- **WHEN** an order is taken and delivered, a toll paid and a rescue made
- **THEN** the stats give the counts, rates per game hour and the average delivery time
