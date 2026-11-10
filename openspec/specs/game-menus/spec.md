# game-menus Specification

## Purpose
The front door and comforts of the game: main menu with courier creation, settings that persist, the address book and a generated ambience.

## Requirements

### Requirement: Main menu and courier
The game SHALL open with a menu to start a new game with a named courier (with pronouns), continue
from the quick save, change settings or quit; the game waits while the menu is open; the courier's
name SHALL appear in story scenes and be saved.

#### Scenario: New game with a named courier
- **WHEN** a new game is started for "Mara Quill" (she/her)
- **THEN** the menu closes, time runs, the save holds the name, and the first scene addresses Mara Quill

### Requirement: Settings
Mouse sensitivity, game speed and volume SHALL be applied and kept between sessions.

#### Scenario: Settings are kept
- **WHEN** the settings are changed
- **THEN** they apply at once and load back from the settings file

### Requirement: Address book
The address book SHALL list the patron, home and the story's people and places with their addresses.

#### Scenario: Address book
- **WHEN** the address book is opened with a patron and a home
- **THEN** it lists the patron's name and address and the home's address

### Requirement: Ambience
The city SHALL hum: a generated ambience, louder and darker deeper below the roof.

#### Scenario: Ambience follows depth
- **WHEN** the ambience levels are taken at the roof and twenty layers down
- **THEN** the deep level is louder and darker
