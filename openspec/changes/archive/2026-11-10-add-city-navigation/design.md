# Design: add-city-navigation

- **Template:** `BlockNav.new(plan)` builds the nodes of one floor in cell-local x/z (y = the
  floor's walking surface): for every corridor a sorted list of points along its centre line
  (door fronts, crossings with the other corridors, its ends), plus one node inside each unit
  1 m behind its door, the stair landing (behind the core's corridor opening) and entrance nodes
  at the main corridor ends. Edges join consecutive points of a corridor, door fronts to unit
  nodes, the core's door front to the landing. Costs are distances.
- **Floors:** node id = floor × template size + template index. `neighbours(id)` adds the landing
  of the floor above and below with the stair walking length (two 3 m flights rising 2 m each
  plus the 1.2 m turn, ≈ 8.4 m).
- **Bridges:** `CityNav` keeps `BlockNav`s in a small cache. An entrance node on the floor of an
  entrance (plan.entrances, not magic ends) links to the matching entrance of the neighbouring
  block (the bridge's other end) with the distance between the two corridor ends.
- **Search:** A* with a straight-line heuristic in coordinates relative to the start cell, a
  node budget (default 60,000) and a box of ±`max_cells` around start and goal. Global nodes are
  `Vector4i(cell.x, cell.y, cell.z, id)`.
- **Places:** `NavPlace(cell, floor, unit, where)` with `where` = UNIT (inside), DOOR (door
  front) or ENTRANCE (floor + face). `NavRoute` holds the global nodes, points relative to the
  start cell and the length.
