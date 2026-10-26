# Proposal: add-pocket-doorways

## Why

Magic doorways are a signature of the city: a modest door in a floating block opens into a
space far vaster than the block itself. They must feel seamless — you see the vast interior
through the door as you approach, you fly through without a loading screen, and you can turn
around and see the city through the door behind you. This change proves that this works in
Godot together with the infinite streaming city and the floating origin.

## What Changes

- **Doorway placement:** some blocks (10%, and every transit hub) carry a glowing doorway on one
  side. If the block has a bridge with room above its deck, the doorway opens where that bridge
  arrives.
- **Pocket spaces:** every doorway leads to a deterministic interior — a hall, garden, bazaar or
  concourse depending on the block's function — at least ten times the volume of the block and
  at least twice as wide and deep. Interiors are placed far out of sight (12 km above their
  doorway) and only one is active at a time: the one belonging to the nearest doorway within
  160 m, or the one the player is in.
- **Portal view:** the active doorway shows a live view of its interior (and the interior's door
  shows the city outside), rendered by a second camera whose pose mirrors the player's through
  the doorway pair.
- **Traversal:** crossing a doorway from its front moves the player to the matching side of the
  other door, keeping position relative to the door, view direction and speed. Crossing from
  behind does nothing.
- **Streaming while inside:** the city around the entrance stays loaded while the player is in a
  pocket space, so stepping back out is instant.

Out of scope (later changes):
- Teleport network between transit hubs → `add-teleport-network`.
- Walking/collision inside pocket spaces → `add-on-foot-movement`.
- Nested doorways inside pocket spaces, several live portals at once, recursive portal views.

## Capabilities

### New Capabilities
- `pocket-doorways`: which blocks carry a doorway and where it sits on the block.
- `pocket-spaces`: the bigger-on-the-inside interiors behind doorways — size, kind, content,
  placement out of sight and activation.
- `portal-traversal`: seeing through doorways and crossing them in both directions.

### Modified Capabilities
- `world-streaming`: adds a separate streaming focus so the city around a doorway stays loaded
  while the camera is inside its pocket space.

## Impact

- New pure logic: `src/core/portal_math.gd`, `src/core/pocket_layout.gd`,
  `src/core/doorway_info.gd`, `src/core/pocket_space_info.gd`.
- New scene code: `src/world/doorway_view.gd`, `src/world/pocket_interior.gd`,
  `src/world/pocket_manager.gd`, shaders `portal.gdshader`, `pocket_surface.gdshader`.
- Changed: `CityWorld` (pocket layout, doorway views per chunk, streaming focus override),
  `ChunkView` (doorway children), `Hud` (pocket read-out), `main.tscn`, screenshot tool.
- New unit and integration tests.
