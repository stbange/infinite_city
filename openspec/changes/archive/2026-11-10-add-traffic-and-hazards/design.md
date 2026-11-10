# Design: add-traffic-and-hazards

- `TrafficLanes(layout)`: a lane boundary `b` on axis X (a 32 m gap at x = b · 64) carries cars
  along z, one on axis Z cars along x. Per layer (cell row y) two heights (row centre −10 m and
  +10 m) and two directions (offset ±6 m from the gap's middle): four tracks. Cars on a track are
  SPACING (80 m) apart at SPEED (24 m/s); the phase comes from `hash(seed, SALT_TRAFFIC, axis,
  boundary, row, track)`. `cars_near(center, radius, seconds)` returns {position, velocity, id}
  with absolute positions (metres); `seconds` is real time (game minutes ÷ clock speed), reduced
  modulo the track period in double precision first.
- `TrafficManager` (world): car bodies (box with head and tail lights) for cars within 220 m,
  pooled; each frame tests the player against car boxes (4.4 × 1.6 × 2.2 m) and emits `hit`.
- `HazardDirector` (world): listens to `Player.rescued` and `TrafficManager.hit`; for a hit it puts
  the player at the fall guard's safe point. Both take `FEE` from the wallet, call
  `JobManager.lose_cargo()` and set `last_message` for the HUD.
