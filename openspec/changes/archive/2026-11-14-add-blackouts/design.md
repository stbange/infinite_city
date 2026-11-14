# Design: add-blackouts

- A blackout event {district, day} is drawn last for each district each day (chance
  `live.blackout_chance`), so earlier draws are unchanged.
- The block instance custom data's fourth channel is the blackout flag; the shader multiplies the
  lit-window share by `1 − flag`. `SimulationRunner` re-flags a chunk view only when the dark set
  it shows changed.
- The lamp is a spot light on the camera; battery drains by game minutes ÷ 600 while on; it is
  saved as the session part "lamp".
