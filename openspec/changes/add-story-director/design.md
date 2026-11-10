# Design: add-story-director

- `StoryDirector` is pure: `cast(population, chronicle, start, patron)`, `begin(plot, state,
  deliveries)`, `deliver_story_job`, `choose(plot, state, index, deliveries)` (returns heat
  effects), `scene_text`, `choice_texts`, `objective`.
- Person casting ranks the residents of housing blocks in rings around the start (±1 layer) by
  `hash(seed, SALT_CAST, role, person)`; the first ring with a candidate wins.
- Beat order is the data order; one beat is active at a time. `done[beat]` keeps the delivery count
  when it finished, for "since" preconditions.
- `StoryRunner` (world) casts on a worker thread once the courier's start is known (its own layout
  and population), then each frame begins beats with `JobManager.completed` as the delivery count,
  inserts story jobs (`DeliveryJob.story_beat` set, pay ¤15) at the front of the bag, listens to
  `JobManager.delivered`, opens scenes in the `DialoguePanel` and applies choices (heat goes to the
  `EncounterDirector`). Saved under the session part "story".
