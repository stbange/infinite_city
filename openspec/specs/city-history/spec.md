# city-history Specification

## Purpose
The generated past of the city: eras, city-wide powers, legends, influence fields, the faction history of every Reach and who owns each district.

## Requirements

### Requirement: Eras
The city history SHALL consist of six eras in this order: the Raising, Building Down, the Sealing,
the Doorway Rush, a war era and the Quiet. They SHALL be contiguous, start at year 0 and end at the
present, year 517. The war era is named after the vital good its antagonist company controls
(for example "the Blackout War" for power), and its outcome (the districts or the company won) is
recorded.

#### Scenario: Era sequence
- **WHEN** the histories of seeds 1 to 50 are generated
- **THEN** each has the six era kinds in order, contiguous, from year 0 to 517
- **AND** each war era names its antagonist company and an outcome

### Requirement: City-wide powers
Each seed SHALL have 6–10 city-wide powers: exactly one Authority, at least three companies that each
control a different vital good (food, power, water, transit or medicine), at least one faith and
exactly one secret society, each with a distinct name and colour.

#### Scenario: Powers of a city
- **WHEN** the histories of seeds 1 to 50 are generated
- **THEN** each satisfies the counts above and no two powers share a name

### Requirement: Legends
Each seed SHALL have 10–20 legends: named people tied to an event of their era. A legend is at
least 16 years old at their event, dies after it or is alive at 517, and is at most 95 years old if
alive.

#### Scenario: Legends fit their events
- **WHEN** the legends of seeds 1 to 50 are examined
- **THEN** every legend's event lies in their lifetime and in an era of the history, and the age rules hold

### Requirement: Influence fields
Every city-wide power SHALL have a strength between 0 and 1 at every district, changing by at most
0.25 between neighbouring districts. Food and water companies SHALL be stronger deep down, and the
Authority stronger near the roof.

#### Scenario: Smooth and bounded
- **WHEN** strengths are sampled at 2,000 districts and their six neighbours
- **THEN** every value lies in [0, 1] and neighbouring values differ by at most 0.25

#### Scenario: Depth preferences
- **WHEN** the average strength of the food company and of the Authority is measured over districts 1–3 and 60–80 district layers below the roof
- **THEN** the food company is stronger deep down and the Authority is stronger near the roof

### Requirement: Reach histories
Each Reach (4 × 4 × 4 districts) below the sky SHALL have a history of 8–16 local factions (with
replacements for collapsed ones) and their events, in chronological order. Every event's actors
exist at the event's year. At year 517 at least one gang, one party and one guild of the Reach are
alive.

#### Scenario: Living local factions
- **WHEN** 40 Reaches below the roof are generated
- **THEN** each has between 8 and 24 factions in total, and at least one gang, one party and one guild alive at 517

#### Scenario: Consistent events
- **WHEN** the events of those Reaches are examined
- **THEN** they are sorted by year, each lies within 0–517, and every actor was founded before and not dissolved before the event's year

#### Scenario: Things happen
- **WHEN** the events of 40 Reaches are counted
- **THEN** every Reach has at least 20 events, including at least one takeover of a district

### Requirement: Territory
Every district of a Reach below the sky SHALL have exactly one owner — a faction that exists in that
year — at every year from the Building Down era on, and the owner at 517 is the present owner.

#### Scenario: One owner per district
- **WHEN** the owners of all districts of 10 Reaches are queried at years 100, 300 and 517
- **THEN** every district has an owner that exists at that year

### Requirement: Local and deterministic
A Reach's history SHALL depend only on the seed, the Reach and the city history: generating Reaches in
a different order or with a different generator gives identical histories. A border feud with a
neighbouring Reach SHALL refer to that Reach's first gang, as found without generating its history.

#### Scenario: Order does not matter
- **WHEN** Reach (0, -2, 0) is generated alone, and again after its six neighbours, by another chronicle
- **THEN** both histories have the same factions, events and territory

#### Scenario: Border feuds stay local
- **WHEN** a Reach's border-feud events are examined
- **THEN** each names the first gang of the neighbouring Reach as that Reach's seeding would found it
