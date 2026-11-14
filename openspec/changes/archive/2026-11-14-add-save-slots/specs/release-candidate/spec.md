## ADDED Requirements

### Requirement: Save slots and sleeping
The menu SHALL save into new named slots and list the newest to load; sleeping at home SHALL move
time to 07:00 and save into the autosave slot.

#### Scenario: Save slots in the menu
- **WHEN** a new slot is saved, time passes and the slot is loaded from the menu
- **THEN** it is listed first and loading it closes the menu

#### Scenario: Sleeping at home saves
- **WHEN** the courier sleeps at home at 22:00
- **THEN** it is 07:00 the next day and the autosave is listed
