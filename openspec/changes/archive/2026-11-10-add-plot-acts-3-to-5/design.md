# Design: add-plot-acts-3-to-5

- Role kind `flat`: the first vacant flat of the housing blocks in rings around the start (on the
  layer `layer` relative to it); entry key = the flat's slot-0 person id key, `first` = the role's
  display name.
- `StoryDirector.choose` returns {heat, wallet, world, kill}: beat fields `heat` (role → amount),
  `wallet`, `world` (effect names) and `kill` (roles).
- `StoryRunner` applies heat to the encounter director, wallet to the job manager, deaths and world
  effects through `SimulationRunner.record` and `story_effect`: `prices_fall` (0.7) and
  `prices_soar` (2.5) for the live districts and the patron's district, `gang_takes_bridges` for
  every bridge within two cells of the patron.
- The beat-graph test now requires that the end of the story (`story_done`) stays reachable from
  every state.
