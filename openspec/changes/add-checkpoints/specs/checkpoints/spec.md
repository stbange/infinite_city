## ADDED Requirements

### Requirement: Authority checkpoints
Some bridges just below the roof SHALL be Authority checkpoints: a courier with cargo pays a permit
unless they hold light rights; contraband is always found and costs a bribe or is confiscated.

#### Scenario: Checkpoints near the roof
- **WHEN** the bridges around the start are examined at the roof layers and deeper down
- **THEN** some at the roof layers are checkpoints and none deeper down

#### Scenario: What a checkpoint wants
- **WHEN** couriers with nothing, with food, with food and light rights, and with contraband reach a checkpoint
- **THEN** they pass, pay a permit, pass, and are asked for a bribe above the toll

#### Scenario: Contraband at a checkpoint
- **WHEN** the courier carrying contraband refuses the bribe
- **THEN** the contraband is confiscated, the rest kept, and nobody gives chase

#### Scenario: Permits and light rights
- **WHEN** a courier with light rights crosses, and later one without them pays
- **THEN** the first passes and the second pays the permit

### Requirement: Light rights
Light rights SHALL be bought with a silver licence and the fee, and saved.

#### Scenario: Light rights
- **WHEN** a bronze courier, then a silver courier, buys light rights
- **THEN** the first is refused, the second pays and keeps them after a save
