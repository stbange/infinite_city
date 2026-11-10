# Proposal: add-routines

## Why

M5 (a living district): before people can be seen, the game has to know where each of them is at
any time — at home, at work, on the way, or out for the evening — consistent with their home,
their job and the hour, without simulating anyone.

## What Changes

- **Day plans:** a pure function of person and day gives an ordered list of segments: commute to
  work, the shift, commute home, an evening out at a nearby food place on some days, and home
  (asleep at night) in between.
- **Shifts** follow the workplace's opening hours: around-the-clock places run three eight-hour
  shifts, long-open places an early and a late shift, short-open places one; two days off a week.
- **Routine at a time:** what a person is doing at a game minute, where (a place they are at or
  walking to) and, when walking, where from and since when.

## Capabilities

### New Capabilities
- `routines`: day plans and the activity and place of a person at a time.

## Impact

- New `src/core/routines.gd`, `routine_step.gd`; `JobMarket.local_of`; tests
  `test/unit/test_routines.gd`.
