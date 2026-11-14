# Proposal: add-first-night-guide

## Why

M11: a new player should learn the loop by doing it. Today nothing tells them to go to the counter,
press E at a door, answer a scene or open the shop.

## What Changes

- Short prompts on the HUD for the first order, the first delivery, the first scene and the shop;
  each disappears once its action has happened, and progress is saved.

## Capabilities

### New Capabilities
- `first-night-guide`: the step-by-step prompts of the first night.

## Impact

- New `src/core/first_night_guide.gd`, `src/world/session_coach.gd`; signals on the encounter and
  hazard directors; HUD; main scene; tests.
