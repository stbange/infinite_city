# Proposal: add-plot-acts-3-to-5

## Why

M10 of the Fogline plan: the complete first arc. Acts 3 to 5 of "The Hidden Abundance" — the tin,
the important cargo, the vault — and four endings that rewrite the district through the event log.

## What Changes

- **New roles:** the Lamplighter's burnt-out flat and the sealed door of the vault (vacant flats
  near the start, the vault one layer down), and an organizer of the idealist faction.
- **Act 3 — the tin:** the keeper dies (a plot beat, recorded as a death in the event log); their
  last order sends a sealed tin to the Lamplighter's address; the key inside makes every faction
  interested.
- **Act 4 — important cargo:** medicine for the friend, a drive with proof for the organizer; the
  disruptor gang hurts the friend for knowing the courier.
- **Act 5 — the vault:** the key goes to the sealed door; four choices end the story: open it to
  everyone (prices fall), sell it to the monopolist (¤800, prices soar), give it to the gang (it
  takes the bridges around the patron), or lock it again.
- **Beat effects:** beats may kill a cast person, pay the courier and change the world (prices,
  bridges); story jobs carry their cargo tier.

## Capabilities

### Modified Capabilities
- `story-director`: named deaths by plot beats, world effects of endings, place roles.

## Impact

- `data/plot_hidden_abundance.json`; `StoryDirector` (flat roles, effects); `StoryRunner` and
  `SimulationRunner` (story effects); tests extended.
