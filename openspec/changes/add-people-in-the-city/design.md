# Design: add-people-in-the-city

- `PeopleManager` (Node3D) needs the world (population, origin, background), the session clock,
  the player and optionally the interaction node. It owns a `Routines` and a `CityNav`.
- **Candidates** (rebuilt when the player changes cell or floor): the block of the player's cell
  and of its eight horizontal neighbours; floors within ±2 of the player's height; housing blocks
  give their residents (from `block_people`), other blocks the staff of their workplaces (only
  once the district's job market is ready).
- **Placement** of a routine step: inside the unit (unit node plus a small offset per person, at
  the floor) for `working`, `out` and awake `at home`; walkers at `distance = (now − start) /
  clock.speed × WALK_SPEED` along their route (scene position = cell centre of the route's start
  cell + point); none for `sleeping`.
- **Budget:** `CANDIDATES_PER_FRAME` routine evaluations and `ROUTES_PER_FRAME` route searches per
  frame; steps are cached per person until their end minute; routes per person and step.
- **Agents:** a pool keyed by person; capsule body tinted by activity (work teal, out amber, home
  violet, walking white) with a head; walkers face their direction. Shown: nearest MAX_AGENTS
  within VIEW_DISTANCE of the player.
- **Interaction:** a provider returns agents within reach: label "Name, age · activity", kind
  "person", payload person key.
