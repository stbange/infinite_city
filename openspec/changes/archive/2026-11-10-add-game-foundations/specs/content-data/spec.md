## ADDED Requirements

### Requirement: Data tables
Content tables SHALL live as JSON in `res://data/` and each SHALL pass its schema (required keys
with expected types) when loaded.

#### Scenario: All tables are valid
- **WHEN** every table in `res://data/` is loaded with its schema
- **THEN** none reports a problem

#### Scenario: Problems are reported
- **WHEN** a table misses a required key or has a value of the wrong type
- **THEN** loading reports the key and the problem

### Requirement: Generated names
Names SHALL be generated from naming cultures (syllable tables) deterministically from a culture and
an id: the same id always gives the same name, different ids give varied names, and every name is
2–14 letters per part.

#### Scenario: Same id, same name
- **WHEN** 1,000 ids are named twice by two generators
- **THEN** every name agrees

#### Scenario: Varied names
- **WHEN** 1,000 ids of one culture are named
- **THEN** at least 600 full names are distinct and every part is 2–14 letters long

### Requirement: Text templates
A text template SHALL fill `{path.to.value}` slots from a dictionary and choose one option of each
`[a|b|c]` group deterministically from a seed.

#### Scenario: Slots and variants
- **WHEN** "[Hi|Hello] {who.first}" is filled for who.first = "Ma" with two seeds
- **THEN** each result starts with "Hi" or "Hello", ends with "Ma", and the same seed always gives the same result

### Requirement: Background jobs
Expensive results SHALL be computable on worker threads and cached by key: a job submitted once is
computed once, and its result is available when it is done.

#### Scenario: Computed once
- **WHEN** the same key is submitted three times and the job finishes
- **THEN** the job ran once and the result is available under that key

### Requirement: Unique salts
Every hash salt constant (named SALT_*) in the scripts of `src/core/` SHALL have a value no other
salt constant has.

#### Scenario: No two salts agree
- **WHEN** the SALT_* constants of all scripts in `src/core/` are collected
- **THEN** their values are pairwise distinct
