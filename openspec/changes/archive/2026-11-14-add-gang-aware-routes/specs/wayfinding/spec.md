## ADDED Requirements

### Requirement: Gang-aware routes
Routes SHALL be able to avoid bridges held by gangs: crossing one costs extra, so a detour is taken
when there is one and the extra cost is paid when there is none.

#### Scenario: Gang bridges cost more
- **WHEN** a route across a bridge is found again with that bridge penalised
- **THEN** either a longer detour avoids it, or the route still crosses it at the penalty's cost

### Requirement: Chases on the graph
Chasing gang members SHALL follow paths over the navigation graph to the courier.

#### Scenario: Chasers follow the graph
- **WHEN** the courier runs off the bridge into a block and up a floor
- **THEN** every chaser has a path through the block and closes in along it
