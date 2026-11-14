# Proposal: add-figure-animation

## Why

M13: figures glided as single capsules; facing one only showed a label.

## What Changes

- **Figures:** a torso, a head and two legs that swing while the figure moves and settle when it
  stands, still cheap enough for 40 figures.
- **Gossip:** pressing E on a figure shows something they know from the relations (gossip), in the
  HUD's messages.

## Capabilities

### Modified Capabilities
- `people-in-the-city`: walking figures and gossip.

## Impact

- `PersonAgent.animate`, `walk_phase`; `PeopleManager` animates and answers E; HUD messages.
