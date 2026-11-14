# first-night-guide Specification

## Purpose
Prompts that teach a new courier the loop on the first night, one action at a time.

## Requirements

### Requirement: First-night prompts
The HUD SHALL prompt the next thing to learn — take an order at the patron's door, deliver it,
answer a scene, open the shop — until each has been done once; progress SHALL be saved.

#### Scenario: The guide steps through the first night
- **WHEN** the steps are done in order
- **THEN** each prompt gives way to the next, the patron is named, and a saved copy is finished too

#### Scenario: Guide in play
- **WHEN** the courier takes an order, delivers it, answers a scene and opens the shop
- **THEN** the guide is finished and the session stats count the delivery
