# Proposal: add-relations

## Why

Fogline's people need lives that connect: families across flats, colleagues, friends, secret
lovers, rivals and enemies, so that deliveries, gossip and the story can use them. Milestone M3.

## What Changes

- **Family:** partners, parents and children within a household; relatives in other flats of the
  same block who share a family line (and family name); flatmates.
- **Neighbours:** adults in the units next door on the same floor.
- **Colleagues:** people working at the same workplace.
- **Friends, secret lovers, rivals:** decided per pair within social circles (the floor, the block,
  the workplace) by a pair hash, so they are always mutual.
- **Enemies:** members of factions that feuded in the Reach's history who share a circle.
- **Gossip:** a few lines a resident would say about the people they know and the local history;
  the residents card shows one.

Out of scope: relations changing during play (M9); dialogue scenes (M7).

## Capabilities

### New Capabilities
- `relations`: family, neighbours, colleagues, friends, lovers, rivals, enemies and gossip.

### Modified Capabilities
- `residents`: family names follow the family line (relatives in a block share a name).

## Impact

New `src/core/relation.gd`, `relations.gd`, `gossip.gd`, `data/gossip.json`; `Population` gets a
per-block cache of adults and family lines; the HUD card shows a gossip line.
