# Design: add-route-hints

- The route starts at the nav node nearest the courier on their floor of the block in their cell
  (`nearest_node`), and ends at the target door's node; searches are capped at 20,000 nodes.
- Lights every 2.5 m along the route, kept within 30 m (+ 2 m) of the courier; unlimited for
  `FULL_SECONDS` after a scan. Lights are unshaded spheres from a pool.
- `NavRoute.length` is now the walking length (stairs at their flight length); `cost` is what the
  search minimised, which differs once penalties apply.
