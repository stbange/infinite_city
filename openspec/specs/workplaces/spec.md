# workplaces Specification

## Purpose
Where the city works: workplaces with business names, opening hours and job slots, and the job market that assigns every working-age adult.

## Requirements

### Requirement: Workplaces and job slots
Every non-core unit of a block that is not housing, on every floor, SHALL be a workplace of the
block's function with a business name, opening hours and a number of job slots (0 means vacant).
Job slots are scaled per district so that their total is between 85% and 100% of the district's
working-age adults (18–67).

#### Scenario: Slots cover the workforce
- **WHEN** the job markets of 3 districts are built
- **THEN** each district's total slots are between 85% and 100% of its working-age adults, and every workplace has a name and opening hours

### Requirement: Job market
Each working-age adult SHALL work at no more than one workplace in their district, assigned
deterministically; a workplace's staff SHALL be exactly the adults assigned to it and never exceed
its slots. Children and people over 67 have no job.

#### Scenario: Both directions agree
- **WHEN** the job market of a district is built
- **THEN** every employed adult appears in their workplace's staff, every staff member is assigned to that workplace, and no staff exceeds its slots

#### Scenario: Employment
- **WHEN** the job markets of 3 districts are built
- **THEN** between 70% and 95% of working-age adults are employed and nobody outside 18–67 is

#### Scenario: Same market every time
- **WHEN** a district's job market is built twice by two populations
- **THEN** every assignment agrees

### Requirement: Job market budget
Building a district's job market SHALL take under 1.5 s, and the world SHALL prefetch the market of
the player's district on a worker thread.

#### Scenario: Build time
- **WHEN** a district's job market is built
- **THEN** it takes under 1.5 s
