## ADDED Requirements

### Requirement: Start scenario
The start SHALL give the player a patron — the nearest active food business (a workplace with
staff whose trade sells food) within 3 cells horizontally and 2 layers of the start — and a home,
the nearest vacant flat.

#### Scenario: Patron and home near the start
- **WHEN** the start scenario of the main scene's spawn cell is found
- **THEN** the patron is an active food business within range and the home is a vacant flat

### Requirement: Food orders
A patron SHALL offer three orders per game hour, each from an occupied flat within 2 cells
horizontally and 1 layer of the patron, for an adult of that flat, the same for the same patron,
day and hour.

#### Scenario: Orders near the counter
- **WHEN** the orders of a patron are listed for 24 hours of a day
- **THEN** each hour has three orders, every customer is an adult living at the drop-off within range, and listing again gives the same orders

### Requirement: Pay and tips
A delivery's pay SHALL be 12 credits plus 0.15 per metre between the patron and the customer's
block plus 3 per floor of difference, plus a tip of up to 40% that falls linearly to zero as the food
cools over 30 game minutes after pickup.

#### Scenario: Hot food pays better
- **WHEN** the same order is delivered after 5 and after 40 game minutes
- **THEN** the first pays more and the second pays exactly the base pay

### Requirement: Accepting and delivering
Interacting with the patron's door SHALL accept the next open order of the current hour (up to three
carried at once); interacting with an accepted order's drop-off door SHALL deliver it and add its
pay to the wallet. The patron's door is labelled "Jobs at <name>", a drop-off door "Deliver to
<customer>".

#### Scenario: A delivery from counter to door
- **WHEN** the player faces the patron's door and interacts, then faces the order's drop-off door and interacts
- **THEN** the order is accepted, then delivered, and the wallet grows by its pay

### Requirement: Rent
Rent of 120 credits SHALL be charged every Monday at 06:00; a wallet that cannot pay goes into debt.

#### Scenario: Monday rent
- **WHEN** the clock passes Monday 06:00 with 100 credits in the wallet
- **THEN** the wallet holds -20 credits

### Requirement: Waypoint
While carrying an order the HUD SHALL show an arrow, the distance and the floor difference to its
drop-off door, otherwise to the patron's door, plus the wallet and the carried orders.

#### Scenario: Waypoint read-out
- **WHEN** the player carries an order
- **THEN** the HUD shows the customer's name, the distance in metres and the wallet

### Requirement: Saved courier state
The save SHALL include the wallet, the carried orders and the completed count.

#### Scenario: Courier state survives a reload
- **WHEN** a session with money and a carried order is saved and loaded
- **THEN** the wallet and the carried order are restored
