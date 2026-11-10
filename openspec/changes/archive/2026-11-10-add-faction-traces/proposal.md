# Proposal: add-faction-traces

## Why

The generated history (`city-history`) is invisible so far. Players should see whose city they are
in: gang tags where turf ends, memorials where wars and blackouts struck, burnt-out blocks, and a
read-out naming the turf and the Reach. Milestone M1 of the Fogline plan, part 2.

## What Changes

- **Gang tags:** blocks of a gang-owned district on its edge towards a district with another owner
  carry 1–3 small neon tags in the gang's colour.
- **Memorials:** every district that suffered a raid or blackout has a white memorial sign on the
  block of its memorial cell (when that cell holds a block).
- **Ruins:** in those districts about a quarter of the blocks are ruined: almost no lit windows and a
  scorched facade.
- **Read-out:** the HUD names the owner of the district and the Reach ("Turf: the Ash Walkers ·
  Juniper Reach").
- **Debug timeline:** F3 shows the current Reach's factions and recent events.

Out of scope: residents (M2), bridge tolls (M6).

## Capabilities

### New Capabilities
- `faction-traces`: how the history shows in the city and the HUD.

### Modified Capabilities
(none)

## Impact

New `src/core/trace_layout.gd`; `CityWorld` owns a `CityChronicle` and adds traces when loading
chunks; `ChunkView` writes a ruin flag into block instance data; `block.gdshader` darkens ruins;
`Hud` shows turf and the debug timeline; `project.godot` gets `toggle_debug` (F3).
