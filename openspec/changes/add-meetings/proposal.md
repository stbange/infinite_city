# Proposal: add-meetings

## Why

M13: story scenes only started on deliveries. People in the story should be met where their day
puts them — the friend on the ward, the patron behind the counter.

## What Changes

- **Meet trigger:** a beat can wait until the courier meets a cast person: walking up to their
  figure (within 3.5 m) or knocking on the door of the unit their routine puts them in now (their
  home when routines are not known yet). The objective names where they are now.
- *The Hidden Abundance*: the friend's beat in Act 4 now waits for a meeting.

## Capabilities

### Modified Capabilities
- `story-director`: the meet trigger.

## Impact

- `StoryState.meet_role`, `StoryDirector.met`; `StoryRunner.meet_place`, people, player and
  interaction paths; the beat-graph test explores meetings.
