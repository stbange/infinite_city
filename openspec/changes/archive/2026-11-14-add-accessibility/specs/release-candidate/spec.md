## ADDED Requirements

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
