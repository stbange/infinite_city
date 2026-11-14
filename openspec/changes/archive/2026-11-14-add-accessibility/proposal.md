# Proposal: add-accessibility

## Why

M18: settings that let more people play: bigger text, faction colours that stay apart for colour-
blind players, still fog, and their own keys.

## What Changes

- **Text size** (0.75–2×) scales every panel.
- **Colour-blind-safe faction colours:** faction signs and tags use the nearest colour of the
  Okabe–Ito palette.
- **Reduced motion:** fog banks stand still.
- **Key rebinding** for interact, flying, sprint and the movement keys, from the menu.
- **Fog-limited streaming:** below the fogline the world streams two chunks out instead of four,
  since the fog hides anything beyond a few hundred metres.

## Capabilities

### Modified Capabilities
- `release-candidate`: accessibility and fog-limited streaming.

## Impact

- `GameSettings` (text scale, colour-blind, reduced motion, bindings), new
  `src/core/faction_palette.gd`; `TraceLayout` sign colours; `CityFog` wind; `GameMenu` controls;
  `CityWorld.fog_radius_h`, `effective_radius_h`; tests.
