# Design: add-side-arcs

- Side arcs end with the flag `side_done`; the beat-graph check uses it as the target.
- The side runner waits for the main cast, then casts with the main cast's keys excluded. Its story
  jobs carry ids "side:<beat>", the main runner's "story:<beat>", so deliveries go to the right arc.
- Only the runner whose scene the panel shows acts on a choice (`_showing`).
