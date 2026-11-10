# dialogue Specification

## Purpose
The scene panel that shows a story scene with the cast's names and lets the courier pick a numbered choice.

## Requirements

### Requirement: Scene panel
A scene SHALL be shown in a panel with the cast's names filled in and numbered choices that the
courier picks with the keys 1–3; picking closes the panel.

#### Scenario: Picking a choice
- **WHEN** a scene with two choices is open and the courier picks the second
- **THEN** the panel closes and the second choice's flags are set
