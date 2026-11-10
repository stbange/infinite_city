# Proposal: add-plot-templates

## Why

M10: a new seed should tell a different story. With one template every city gets the same arc;
two more templates and a per-seed choice make the plot depend on the world.

## What Changes

- **"The Election"** (three acts): a fixer, a bribed voter, a whistleblower with a ledger; expose
  the council (prices fall), sell the ledger (¤500) or burn it.
- **"The Plague"** (three acts): a cough spreads, a ward doctor needs samples, a quarantine paid for
  by a medicine company; smuggle the cure (prices fall, a gang remembers), obey, or sell the
  formula (¤600, prices soar).
- **Choosing a template:** each template scores its fit with the start's Reach (a food company for
  the Hidden Abundance, parties for the Election, a medicine company for the Plague) plus a per-seed
  jitter; the best one is cast and played.

## Capabilities

### Modified Capabilities
- `story-director`: more templates and choosing one per seed.

## Impact

- New `data/plot_election.json`, `data/plot_plague.json` (shared plot schema);
  `StoryDirector.TEMPLATES`, `pick_template`; `StoryRunner` casts the chosen template and restores
  it from saves; tests run every check on every template.
