# save-games Specification

## Purpose
Saving and loading a game session: seed, clock and the player's place, view and mode, as versioned JSON.

## Requirements

### Requirement: Save and load
A game session SHALL save the world seed, the clock, the player's absolute position (metres, 64-bit),
view direction and movement mode as JSON with a format version, and loading it SHALL restore them.

#### Scenario: Round trip
- **WHEN** a session at a given place, view, mode and time is saved and then loaded into a fresh session
- **THEN** the clock, mode and view are identical and the absolute position matches within 1 cm

#### Scenario: Deep positions keep their precision
- **WHEN** a session 640,000 km below the roof is saved and loaded
- **THEN** the absolute position matches within 1 cm

#### Scenario: Unknown versions are refused
- **WHEN** a save with a newer format version is loaded
- **THEN** loading fails with a message and the session is unchanged
