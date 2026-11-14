## ADDED Requirements

### Requirement: Panels and messages
The read-out SHALL show the place and the courier in separate panels, and short messages from
saves, tools, the shop, rescues and gangs in one queue where each shows briefly.

#### Scenario: Messages show briefly
- **WHEN** messages arrive, repeat, age and overflow
- **THEN** a repeat is not shown twice, messages fade after six seconds, and at most four show at once, newest last
