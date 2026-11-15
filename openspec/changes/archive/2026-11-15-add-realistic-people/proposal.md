## Why

The people in the city were capsules with a head: all the same size, swinging stiff legs, in
saturated colours. They read as tokens, not as residents. A city in space should be full of people
who look like people: tall and short, young and old, dressed for work or for home.

## What Changes

- Every resident gets a deterministic **look** from their age, pronoun, skill and the seed: height
  and build, skin tone, hair that greys and thins with age, everyday and work clothes in muted
  tones, an old person's stoop and slower pace.
- Figures become **jointed bodies**: pelvis, legs with knees and feet, torso, arms with elbows and
  hands, neck and head with hair, sized by the look.
- Figures **walk**: legs swing against each other, knees bend only backwards, each arm swings
  against its leg, the body bobs, stride and cadence follow speed and pace; they turn smoothly and
  stand breathing when still.
- Gang members, wardens and escorts use generic adult looks.

## Capabilities

### New Capabilities
- `realistic-people`: looks and jointed, walking figures.

## Impact

- New `src/core/figure_look.gd`; rewritten `src/world/person_agent.gd`; people manager, doorstep,
  escort and encounter director pass looks.
