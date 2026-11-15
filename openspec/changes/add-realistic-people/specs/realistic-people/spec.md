## ADDED Requirements

### Requirement: Looks
Every resident SHALL have a look that is a pure function of the person and the seed: a height
from their pronoun and age (adults about 1.5–1.95 m, children shorter by age), a build, a skin
tone from a realistic palette, hair that greys with age, an older person's stoop and slower pace,
and everyday and work clothes in muted tones.

#### Scenario: Looks are their own
- **WHEN** the look of the same person is computed twice, and the looks of a hundred people
- **THEN** the two are identical, and nearly all of the hundred differ

#### Scenario: Heights by age and pronoun
- **WHEN** the looks of the residents around the spawn are computed
- **THEN** adults are 1.45–2.0 m tall, young children are under 1.4 m, and women average shorter
  than men

#### Scenario: Age shows
- **WHEN** residents aged 70 or more are compared with residents under 35
- **THEN** most of the old are grey, all stoop and walk slower, and almost none of the young are
  grey or stoop

#### Scenario: Realistic tones
- **WHEN** looks are computed
- **THEN** skin comes from the skin palette and clothes have a saturation of at most 0.5

### Requirement: Jointed walking figures
A person's figure SHALL be a jointed body sized by their look whose head ends at their height.
While it moves, its legs SHALL swing against each other, its knees SHALL bend only backwards and
each arm SHALL swing against its leg, at a cadence from speed and pace; standing still, its limbs
SHALL come to rest. It SHALL wear work clothes while working.

#### Scenario: Bodies and gait
- **WHEN** a 1.8 m figure and a 1.1 m figure are built and the first walks forward then stops
- **THEN** their heads end at 1.8 m and 1.1 m, the legs and arms swing against each other with the
  knees bending backwards, and the legs come to rest when it stops

#### Scenario: Clothes follow the activity
- **WHEN** a figure starts working and then goes home
- **THEN** it wears its work top at work and its everyday top at home
