# Proposal: add-block-interiors

## Why

The player can now walk along bridges, but every block is a sealed box. The city should be a
real place: walk in from a bridge, follow corridors, climb the stairs, step into flats and rooms
and see how people live and work there — in the same dark, neon-lit mood as outside.

## What Changes

- **Floor grid:** block heights and bridge decks snap to a world-wide 4 m floor grid, and bridges
  run along the line through both cell centres, so every bridge arrives exactly at a floor and at
  a corridor end.
- **Floor plans:** every block has whole 4 m floors with a corridor cross along the cell centre
  lines reaching all four faces, extra corridors in deep blocks, rows of units opening onto the
  corridors, and a switchback stair core from the lowest floor to a hut on the roof.
- **Entrances and windows:** an opening where each bridge meets its block (except at magic
  doorways); real windows matching the façade's 4 m window grid.
- **Flats and rooms:** housing units become flats with a bathroom, a bed, seating, a kitchen
  counter and a table; other functions get themed units — offices with glowing screens, shops,
  grow racks, machine halls, gardens, hospital wards, classrooms. Every room has its own light.
- **Entering blocks:** blocks within 12 m of the player are built from the plan (at most two at a
  time, a floor per frame); their sealed box is swapped for the real shell, floors, stairs and
  furniture, with full collision on the player's floor and the floors next to it.
- **Read-out:** inside a block the read-out names the floor and the room.

Out of scope (later changes):
- Lifts, doors that open and close, people and NPCs, interactive objects.
- Interiors far from the player (only nearby blocks are built).

## Capabilities

### New Capabilities
- `block-interiors`: floors, corridors, units, stairs, entrances, windows, furnishing, room light
  and how nearby blocks become enterable.

### Modified Capabilities
- `city-layout`: blocks follow the 4 m floor grid.
- `city-bridges`: bridge decks lie on the floor grid and on the line through both cell centres.

## Impact

- `CityLayout` block geometry (vertical) and bridge geometry change: the generated city changes
  (seeds produce a different but equally valid city).
- New pure logic: `src/core/interior_plan.gd`, `interior_unit.gd`, `entrance_info.gd`,
  `interior_floor.gd`, `room_info.gd`, `interior_layout.gd`, `furnisher.gd`.
- New scene code: `src/world/interior_view.gd`, `src/world/interior_manager.gd`,
  `src/world/shaders/facade.gdshader`; `ChunkView` can hide a block and its collider; `Hud` shows
  floor and room; `CityLights` also uses room lights; `main.tscn`.
