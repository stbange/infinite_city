# Proposal: add-export-builds

## Why

M18 of the plan (draft 2): something people can download and play.

## What Changes

- **Export presets** for Linux, Windows and macOS (`export_presets.cfg`): the data tables ship with
  the game, tests and tools stay out, builds go to `build/`.
- **Scripts:** `scripts/install-export-templates.sh` fetches Godot's export templates for the
  pinned version; `scripts/export.sh` exports any or all presets.
- **Release workflow:** on a `v*` tag, CI runs the tests, exports all three builds, packages them
  and attaches them to the GitHub release.

## Capabilities

### New Capabilities
- `release-candidate`: builds, accessibility, sound, save slots and fog-limited streaming.

## Impact

- New `export_presets.cfg`, `scripts/export.sh`, `scripts/install-export-templates.sh`,
  `.github/workflows/release.yml`; `.gitignore` builds; tests.
