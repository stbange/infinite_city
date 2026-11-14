# Design: add-escorts

- `Escort` keeps the figure's position relative to a cell centre (floating origin), replans a path
  every 0.5 s from its nearest node to the courier's (one-cell box, 4,000 nodes) and stops 2 m short.
