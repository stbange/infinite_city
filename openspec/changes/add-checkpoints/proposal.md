# Proposal: add-checkpoints

## Why

M15 of the plan (draft 2): the concept's Authority checkpoints at the fogline were missing, and so
were light rights, the courier's way past them.

## What Changes

- **Checkpoints:** a quarter of the bridges in the two layers just below the roof are run by the
  city's authority. A courier with cargo pays a permit (¤15); contraband or data is found even with
  light rights, and costs a bribe (three times the toll) or is confiscated (no chase, more heat).
  Refusing a permit means a chase by wardens.
- **Light rights:** bought in the shop with a silver licence (¤800); free passage with ordinary cargo.

## Capabilities

### New Capabilities
- `checkpoints`: Authority checkpoints and light rights.

## Impact

- `EncounterRules.is_checkpoint`, `checkpoint`; `EncounterDirector` checkpoint offers and
  confiscation; `CourierState.light_rights`, `buy_light_rights`; shop entry; economy section
  `checkpoints`; tests.
