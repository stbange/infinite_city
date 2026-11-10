# Design: add-relations

`Population.block_people(block)` caches, per block, every person's id, age, household slot role and
family line (LRU of 64 blocks). The family line of a household is
`hash(seed, SALT_LINE, cell, floor·128+unit) % max(1, flats / 5)`, so roughly five households of a
block share a line; `family_seed_of()` becomes the line's seed (names follow the line). Circle ids:
floor = (cell, floor), block = cell, workplace = its unit id. Pair hash
`hash4(seed, SALT_PAIR + circle kind, circle id, min(local), max(local), kind)` against k / n:
friends floor k = 1.2, block k = 2.0, workplace k = 1.2; lovers block k = 0.04; rivals workplace k =
0.25. Enemies: members of two factions with a feud event, within the floor or workplace circle.
Colleagues come from the district's job market (built if needed). `Gossip.about(person)` fills
`data/gossip.json` templates from the person's secret lovers, secret memberships of people they
know, a friend's workplace and the latest takeover in their district.
