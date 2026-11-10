# routines Specification

## Purpose
Where every person is at any time, as a pure function of person and day: commutes, shifts inside opening hours, evenings out, home and sleep.

## Requirements

### Requirement: Day plans
Every person SHALL have a deterministic plan for every day made of segments that follow one
another without gaps, where every walk starts at the place of the segment before it and ends at
the place of the segment after it.

#### Scenario: Continuous plans
- **WHEN** the plans of 300 sampled residents for seven days are examined
- **THEN** the segments of each day are ordered without gaps or overlaps and every walk joins the places around it

#### Scenario: Deterministic routines
- **WHEN** the routine of the same person at the same minute is asked twice from new generators
- **THEN** both answers have the same activity, place and times

### Requirement: Shifts
Employed adults SHALL work five days a week in a shift inside their workplace's opening hours,
and be at their workplace while it lasts.

#### Scenario: Workers at work during their shift
- **WHEN** 200 employed residents are asked for their routine in the middle of their shift on a working day
- **THEN** each is working inside their workplace's unit and the workplace is open then

#### Scenario: Two days off
- **WHEN** the week of an employed resident is examined
- **THEN** they work on exactly five days

### Requirement: Evenings and nights
At night people SHALL be at home, asleep, unless they work a night shift; on some evenings adults
go out to a food place near home that is open then.

#### Scenario: Home at night
- **WHEN** 300 sampled residents are asked for their routine at 03:00
- **THEN** everyone who is not on a night shift is at home and asleep

#### Scenario: Evenings out
- **WHEN** the evenings of 300 sampled adults over seven days are examined
- **THEN** some go out, always to an open food workplace within two cells of home, and come back home
