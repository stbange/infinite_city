## ADDED Requirements

### Requirement: Family
The two oldest adults of a couple or family household SHALL be partners; children SHALL be children
of the household's adults (and the adults their parents); an elder in a family household is a
parent of the oldest adult. Households of the same block with the same family line are relatives:
grown children and parents when their oldest adults are 18 or more years apart, otherwise siblings.
Flatmates are flatmates.

#### Scenario: Households hold families
- **WHEN** 300 couple and family households are examined
- **THEN** the oldest two adults are partners of each other, and every child has each household adult as a parent

#### Scenario: Family lines across flats
- **WHEN** 300 persons with relatives in other flats are examined
- **THEN** each relative lives in the same block, shares the family name and has the mirrored relation (parent ↔ child, sibling ↔ sibling)

### Requirement: Mutual relations
Every relation SHALL be mutual: if A relates to B with a kind, B relates to A with the mirrored
kind (parent ↔ child, every other kind with itself) and the same secret flag.

#### Scenario: Mutuality
- **WHEN** the relations of 400 adults are examined
- **THEN** for every relation A → B there is a mirrored relation B → A

### Requirement: Neighbours and colleagues
Adults in the neighbouring units of the same floor SHALL be neighbours; people working at the same
workplace SHALL be colleagues.

#### Scenario: Who is next door and at work
- **WHEN** 200 employed adults are examined
- **THEN** each has every other staff member of their workplace as a colleague (up to 12 colleagues), and adults next door as neighbours

### Requirement: Friends, lovers and rivals
Friends, secret lovers and rivals SHALL be decided per pair within the circles a person belongs to
(their floor, their block, their workplace) by a hash of the pair, so that the decision is the
same from both sides. Adults have on average 2–6 friends and at least 80% have one; between 2% and
12% of adults have a secret lover outside their household; lovers are secret.

#### Scenario: Social life in numbers
- **WHEN** 600 adults are examined
- **THEN** the friend average, friend share and secret-lover share are in the ranges above, and every lover relation is secret

### Requirement: Enemies from history
Two adults of the same block SHALL be enemies, with a chance decided per pair, when they belong to
two factions with a hostile event between them in their Reach's history (a feud, takeover, strike,
split or buyout).

#### Scenario: Feuds become personal
- **WHEN** enemy relations of 2,000 adults are examined
- **THEN** there are some, and every enemy pair belongs to two factions with a hostile event between them

### Requirement: Gossip
A resident SHALL be able to tell up to three gossip lines about people they know (secret lovers,
secret memberships, workplaces) and their district's history; the residents card shows one line.

#### Scenario: Gossip lines
- **WHEN** gossip of 300 adults is generated
- **THEN** every adult has 1–3 non-empty lines, each naming a person or faction that exists, and the same person always gets the same lines

### Requirement: Fast relations
Once a block's residents are cached, the relations of a person SHALL take under 2 ms on average.

#### Scenario: Relations budget
- **WHEN** the relations of 100 adults of one block are generated after the first
- **THEN** the average time is under 2 ms
