# Proposal: speed-up-tests

## Why

M12: the suite took about six minutes and 5.5 GB. Two unit files (relations, interior floors)
took a quarter of the time, and many unit files rebuilt the same default city and job market.

## What Changes

- **Shared city:** `test/support/shared_city.gd` builds one default layout, chronicle and
  population per test process; unit tests that only read the default city use it. Tests that
  compare fresh generators for determinism still build their own.
- **Right-sized samples:** the relations and interior-floor checks use smaller samples that still
  cover hundreds of people and dozens of blocks.

## Capabilities

### New Capabilities
- `test-suite`: how the suite stays fast and small.

## Impact

- New `test/support/shared_city.gd`; five unit files use it; two files sample less.
