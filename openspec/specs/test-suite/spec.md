# test-suite Specification

## Purpose
How the test suite stays fast and small: one shared default city per process and right-sized samples.

## Requirements

### Requirement: Shared default city in tests
Unit tests that only read the default city SHALL share one layout, chronicle and population per
test process.

#### Scenario: One city per process
- **WHEN** the shared city is asked for twice
- **THEN** the same population comes back
