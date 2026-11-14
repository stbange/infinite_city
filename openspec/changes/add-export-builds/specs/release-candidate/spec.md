## ADDED Requirements

### Requirement: Builds
The game SHALL have export presets for Linux, Windows and macOS that ship the data tables and leave
tests out, and a release workflow that builds all three for a tagged version.

#### Scenario: Three export presets
- **WHEN** the export presets are read
- **THEN** there are presets for Linux, Windows and macOS, each including the data tables, excluding the tests and exporting under build/
