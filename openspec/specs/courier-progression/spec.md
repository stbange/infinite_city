# courier-progression Specification

## Purpose
Growth for the courier: standing with each faction, Couriers' Mutual licences, cargo tiers with better pay, and the tool shop.

## Requirements

### Requirement: Reputation
The courier SHALL have a standing with each faction from −100 to 100 with the levels hostile,
wary, neutral, friendly and trusted; deliveries raise standing with the Couriers' Mutual, and paying
or defying a gang changes standing with it.

#### Scenario: Levels by points
- **WHEN** standing is −60, −20, 0, 30 and 80
- **THEN** the levels are hostile, wary, neutral, friendly and trusted

#### Scenario: Gangs remember
- **WHEN** the courier pays a gang's toll, and later runs from it
- **THEN** standing with that gang first rises, then falls

### Requirement: Licences and cargo tiers
A licence SHALL set the highest cargo tier the courier may carry (bronze 1, silver 2, gold 3);
upgrading needs standing with the Mutual and a fee; with a higher licence some counter orders are
higher-tier cargo with better pay.

#### Scenario: Upgrading the licence
- **WHEN** a bronze courier with Mutual standing 30 and ¤200 upgrades
- **THEN** they hold a silver licence and ¤50, and without the standing the upgrade is refused

#### Scenario: Higher tiers with a better licence
- **WHEN** a day of counter orders is listed for a bronze, a silver and a gold licence
- **THEN** bronze orders are all food, silver adds tier-2 cargo, gold adds tier-3 cargo, and higher tiers pay more for the same trip

### Requirement: Shop
Tools SHALL be sold for a price and only from the licence they need: the scanner and flares from
bronze, the glider and the grapple from silver.

#### Scenario: Buying a tool
- **WHEN** a bronze courier with ¤100 buys the scanner, then tries to buy the glider
- **THEN** the scanner is theirs for ¤60 and the glider is refused
