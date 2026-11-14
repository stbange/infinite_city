# Design: speed-up-tests

- `SharedCity` holds static instances, created on first use; the support folder is not a test
  directory, so GUT does not collect it.
- The plan's disk cache for job markets was not needed once markets were shared within a process.
- A central salt table (`salts.gd`) was dropped: the existing reflection test already checks that
  every `SALT_` constant in `src/core` is unique, which is what the table was for.
