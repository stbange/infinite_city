# Design: add-block-interiors

## Context

Blocks are boxes drawn by `ChunkView` (MultiMesh) with box colliders near the player; the block
shader already paints windows on a world-aligned 4 m grid. Bridges currently land at random
heights and lateral positions. Requirements: the spec deltas.

## Goals / Non-Goals

**Goals:** a believable, walkable, furnished interior for any block; all layout rules pure and
unit-tested; interiors appear seamlessly when the player approaches.

**Non-Goals:** lifts, animated doors, NPCs, building every block's interior (only nearby blocks).

## Decisions

### D1 — Everything on one 4 m grid
Block heights are drawn as whole floors (9–13) with the bottom on the grid, inside the same
clearances as before (cell ± 28 m, always covering the cell centre ± 4 m). Bridge decks sit on a
grid level with a floor above them in both blocks, on the cell centre line. The cell centre is on
the grid (cells are 64 m), so local multiples of 4 m are world grid lines; walls between units
and rooms are placed on grid lines, so they never cut a window (windows span the middle of a bay).

### D2 — Plan (`InteriorLayout.plan_of()` → `InteriorPlan`)
Coordinates relative to the cell centre. Outer walls are 0.3 m thick. Corridors (2.5 m) along
x = 0 and z = 0 form a cross. On each z side, rows of units are stacked away from the main
corridor; while more than 24 m would remain, a row ends at a grid line + 0.75 m and a further
corridor follows, so every row faces a corridor. Rows are split by the x = 0 corridor; units are
2–3 bays wide between grid lines. The first unit east of the crossing on the +z side is the stair
core. Entrances: for each bridge of the block, the floor index is (deck − bottom) / 4 and the face
is where the deck arrives; bridge ends with a magic doorway get none. The plan is identical for
every floor.

### D3 — Floors (`InteriorLayout.floor_of(plan, k)` → `InteriorFloor`)
Produces boxes: slabs (with the stair opening above floor 0), outer wall pieces around windows
and entrances (+ glass panes), unit walls with door gaps, the stair core (flights as ramps for
collision and steps for drawing, landings, divider, and on the top floor the roof hut), rooms,
furniture and room lights. Furniture comes from `Furnisher`, which places items against walls or
on a grid inside each room, rejecting any that overlap walls, other items or the 1 m clear area
in front of doors. Seeds: `(seed, SALT_FLOOR, cell, k)` and per unit index.

### D4 — Shell vs. interior, collision near the player
`InteriorView` draws all floors (so lit rooms are visible through real windows from outside),
building one floor per frame starting at the player's floor. Only when every floor is built does
`ChunkView.set_block_hidden(cell, true)` hide the block's instance (zero-scale) and disable its
collider — the swap is invisible from outside. Collision: the outer shell (one box per face per
floor minus entrances, plus roof and bottom slabs) for all floors; slabs, inner walls, stairs and
furniture only for the player's floor ± 1, rebuilt when the player changes floor.
`InteriorManager` activates blocks within 12 m (at most two) and releases them beyond 30 m.

### D5 — Materials and layers
Interior geometry is on the INTERIOR visual layer (no sunlight). The outer shell is on the CITY
layer with `facade.gdshader`: dark concrete, the sun mask of the block shader, and sun only on
surfaces facing away from the block centre (so inner faces of roof-layer walls stay dark).
Furniture is drawn with per-instance colours (matte MultiMesh) and glowing items (screens, lamps,
grow lights, neon strips) with an emissive MultiMesh. Room lights are light anchors for the
existing `CityLights` pool — only those of the player's floor (slabs cast no shadows, and lights
just under the feet would otherwise win the nearest-first pool), with a softer falloff
(`LightAnchor.attenuation` 1.0) so floors 3.3 m below a light are lit, not only nearby walls. The
Compatibility renderer's per-object light cap is raised to 16, since a floor is one object.

## Risks / Trade-offs

- [Generation time] ~500 boxes per floor in GDScript (≈ 5–10 ms) → one floor per frame.
- [Physics shapes] Full collision for every floor would mean thousands of shapes → only ±1 floor.
- [City changes] Snapping changes block heights and bridge positions for every seed; the specs
  are statistical so tests stay valid; golden screenshots are re-rendered.
- [Painted vs real windows] The lit pattern differs once a block is entered → only nearby blocks,
  and real windows show real rooms.
