# Design: add-meetings

- `begin` sets `meet_role` for trigger "meet"; `met` opens the beat's scene.
- `StoryRunner` checks each frame whether `PeopleManager` shows the person within `MEET_DISTANCE`
  of the player, and listens to `Interaction.interacted` for the person or the door of
  `meet_place()` (routine place when the district's job market is built).
