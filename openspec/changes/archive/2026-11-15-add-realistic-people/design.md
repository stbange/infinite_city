## Context

PersonAgent was a capsule body with two leg boxes. People are drawn up to 40 at a time near the
player within a 5 ms frame budget.

## Decisions

- **Look as pure data** (`FigureLook.of(person, seed)`, salt 220): testable without a scene tree,
  cached per person by the people manager.
- **Heights**: base 1.64 / 1.77 / 1.70 m (she / he / they) plus a near-bell spread from the sum of
  three uniforms (about ±7 cm); children grow linearly from 0.8 m at 2 to adult height at 18;
  people shrink up to 4 % from 60 to 90.
- **Age shows** through smoothsteps: grey from 42 (half of those white), balding chance for
  non-"she" from 32, stoop from 62, slower pace from 60.
- **Muted clothes**: palettes passed through `ArtStyle.mute(…, 0.55)` to fit the grey art style;
  work clothes by skill so a worker is recognisable at work.
- **Shared unit meshes** (capsule, sphere, box) scaled per part and materials cached by colour, so
  many figures cost few resources. Hands, feet and hair extras have a 30 m visibility range.
- **Gait from motion**: the agent measures its own displacement, so any mover (routine walker,
  chaser, escort) animates correctly without telling it its speed.

## Risks

- More nodes per figure (~25): measured 1.3 ms for 40 figures, inside the budget.
