# Proposal: add-traffic-and-hazards

## Why

M6 (dangers), second part: the major traffic lanes are full of flying cars, and the city has no
bottom. Crossing a lane means timing it; a fall or a hit calls the rescue drone, which costs money
and the cargo.

## What Changes

- **Flying traffic:** cars fly along every major lane in both directions on two heights per layer,
  evenly spaced, at positions that are a pure function of lane and time — nothing is simulated far
  away. Cars near the player are drawn with lights.
- **Car hits:** touching a car knocks the courier out of the lane: the rescue drone picks them up.
- **Rescue drone:** after a fall (the existing safety net) or a car hit, the courier is put back on
  the last safe ground, pays a ¤25 fee (what they have if less) and loses the cargo; the HUD says so.

Out of scope (later milestones): checkpoints at the fogline, blackouts (M9 economy and events).

## Capabilities

### New Capabilities
- `flying-traffic`: cars in the major lanes.
- `hazards`: the rescue drone after falls and car hits.

## Impact

- New `src/core/traffic_lanes.gd`, `src/world/traffic_manager.gd`, `src/world/hazard_director.gd`;
  `Player.rescued` signal; HUD line; main scene; tests `test/unit/test_flying_traffic.gd`,
  `test/integration/test_hazards.gd`.
