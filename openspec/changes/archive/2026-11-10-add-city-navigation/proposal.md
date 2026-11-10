# Proposal: add-city-navigation

## Why

Milestone M5 of the Fogline plan (a living district) starts with a way to walk: people need routes
from home to work through corridors, stairs and bridges, and the courier HUD can use the same
routes later. The city has no ground, so blocks and bridges are the whole walkable world.

## What Changes

- **Block navigation:** a graph of one block built from its floor plan: corridor joints, the
  front of every unit door, a point inside every unit, the stair core landing of every floor, and
  the corridor ends where bridges meet the block. One floor template is shared by all floors;
  stairs join landings of neighbouring floors.
- **City navigation:** bridges join the entrances of neighbouring blocks; an A* search over the
  joined graph (block graphs built lazily and cached) gives a route between two places — a unit
  door, a unit or an entrance — with its points and length, bounded so it never searches the whole
  city.

## Capabilities

### New Capabilities
- `city-navigation`: block navigation graphs and routes over blocks and bridges.

## Impact

- New `src/core/block_nav.gd`, `nav_place.gd`, `city_nav.gd`, `nav_route.gd`; tests
  `test/unit/test_city_navigation.gd`.
