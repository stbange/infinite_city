# release-candidate Specification

## Purpose
What makes the game shippable: release builds, accessibility settings, music for chases and scenes, save slots, and streaming that respects the fog.

## Requirements

### Requirement: Builds
The game SHALL have export presets for Linux, Windows and macOS that ship the data tables and leave
tests out, and a release workflow that builds all three for a tagged version.

#### Scenario: Three export presets
- **WHEN** the export presets are read
- **THEN** there are presets for Linux, Windows and macOS, each including the data tables, excluding the tests and exporting under build/

### Requirement: Accessibility settings
Text size, colour-blind-safe faction colours, reduced motion and key bindings SHALL be settable,
applied at once and kept between sessions.

#### Scenario: Colour-blind palette
- **WHEN** faction colours are shown with and without the colour-blind option
- **THEN** they are unchanged without it and drawn from the safe palette with it

#### Scenario: Settings kept and applied
- **WHEN** text size, colour-blind colours, reduced motion and a key are set, saved, loaded and applied
- **THEN** all come back and take effect, the key included

#### Scenario: Rebinding a key
- **WHEN** an action is chosen in the menu and a key pressed
- **THEN** the action uses that key, also after loading the settings

### Requirement: Fog-limited streaming
Below the fogline the world SHALL stream a smaller radius than in the clear air above the roof.

#### Scenario: Fog-limited streaming
- **WHEN** the focus is above the roof, then deep in the fog
- **THEN** the full radius is used above and the fog radius below

### Requirement: Music for the moment
The game SHALL play a pulse during chases and a chord under scenes, with the chase taking over when
both happen.

#### Scenario: Music follows the moment
- **WHEN** music levels are taken for nothing, a chase, a scene, and both
- **THEN** there is silence, a pulse, a drone, and a pulse without the drone

### Requirement: Save slots and sleeping
The menu SHALL save into new named slots and list the newest to load; sleeping at home SHALL move
time to 07:00 and save into the autosave slot.

#### Scenario: Save slots in the menu
- **WHEN** a new slot is saved, time passes and the slot is loaded from the menu
- **THEN** it is listed first and loading it closes the menu

#### Scenario: Sleeping at home saves
- **WHEN** the courier sleeps at home at 22:00
- **THEN** it is 07:00 the next day and the autosave is listed
