# realistic-people Specification

## Purpose
How residents look and move as figures: deterministic looks from age, pronoun and skill, and jointed bodies that walk, turn and stand like people.

## Requirements

### Requirement: Looks
Every resident SHALL have a look that is a pure function of the person and the seed: a height
from their pronoun and age (adults about 1.4–1.95 m, children shorter by age), a build, a skin
tone from a realistic palette, hair that greys with age, an older person's stoop and slower pace,
and everyday and work clothes in muted tones.

#### Scenario: Looks are their own
- **WHEN** the look of the same person is computed twice, and the looks of a hundred people
- **THEN** the two are identical, and nearly all of the hundred differ

#### Scenario: Heights by age and pronoun
- **WHEN** the looks of the residents around the spawn are computed
- **THEN** adults are 1.4–2.0 m tall, young children are under 1.4 m, and women average shorter
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

### Requirement: Body types and women's figures
Every resident SHALL have one of five body types (slim, average, athletic, stocky, heavy), with
heavier bodies more common in middle age and only heavy bodies carrying a belly. Women SHALL have a
bust and a waist narrower than their hips, and many but not all SHALL wear skirts or dresses; men
SHALL wear trousers. Figures SHALL show the body type and garment.

#### Scenario: Body types vary
- **WHEN** the looks of the adults around the spawn are computed
- **THEN** every body type is worn by more than 4 % of them, only heavy bodies have a belly, and
  heavy bodies are more common over 45 than under 30

#### Scenario: Women's figures
- **WHEN** the looks of women and men are compared
- **THEN** every woman has a bust and a waist narrower than her hips, 30–70 % of women wear
  skirts or dresses, and men have no bust and wear trousers

#### Scenario: Body types show
- **WHEN** a slim and a heavy figure, and a woman in a dress, are built
- **THEN** the heavy figure is more than 15 % wider than the slim one, and she wears a dress that
  turns into work clothes when she works
