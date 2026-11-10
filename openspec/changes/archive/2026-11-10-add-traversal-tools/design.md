# Design: add-traversal-tools

- `WalkModel.step` takes `glide`: in the air with glide on, the vertical speed never drops below
  −GLIDE_SINK (3 m/s) and the horizontal target speed is GLIDE_SPEED (9 m/s).
- `TraversalTools` (world) needs the player, the job manager (tools owned, waypoint) and the
  encounter director. The player's `gliding` flag is on while the glider is owned and Space held.
- Grapple: a ray from the eyes along the view up to GRAPPLE_RANGE (20 m) against the physics world
  (the player excluded); on a hit the player moves to the hit point + normal · 0.4 + 1 m up, with
  zero velocity. Out of range nothing happens.
- Scanner: a tall emissive column (no depth test) at the waypoint for SCAN_SECONDS (10 s) when the
  waypoint is within SCAN_RANGE (200 m).
- Flare: during a chase, ends it as an escape and uses one flare.
