# Design: add-figure-animation

- Legs hang from hip nodes and rotate by `sin(phase) · 0.5`; the phase advances at 7 rad/s while
  the figure moved more than 1 cm since the last frame and eases to the nearest rest pose otherwise.
- The frame budget test of the people manager (5 ms in CI, 2 ms target) covers the animation.
