# Proposal: add-doorsteps

## Why

M13 of the plan (draft 2): the residents' lives were invisible at the one moment that matters most
to a courier, the hand-over. Doors opened on nobody.

## What Changes

- **Who answers:** the customer when their routine says they are home and awake; slowly, for half
  the tip, when asleep; a household member at home when the customer is out (80% of the tip);
  otherwise the bag is left at the door (30% of the tip).
- **At the door:** the person who answers stands in the doorway for a few seconds and says a line
  from `data/lines.json`; the line shows in the HUD's messages.

## Capabilities

### New Capabilities
- `doorsteps`: who answers the door, the tip and the hand-over.

## Impact

- New `src/core/doorstep_rules.gd`, `src/world/doorstep.gd`, `data/lines.json`;
  `CourierBoard.pay_for(job, minute, tip_factor)`; `DeliveryJob.paid`; `JobManager.doorstep_path`.
