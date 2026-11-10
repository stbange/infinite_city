# Tasks

## 1. Pure foundations (specs: game-time, content-data)
- [x] 1.1 Write tests for the clock, light level, data tables, names, text templates, salts; verify they fail
- [x] 1.2 Implement `GameClock`, `DataTables`, `NameGenerator`, `TextTemplate`, `data/`; verify they pass

## 2. Session, interaction, background jobs (specs: game-time, interaction, save-games, content-data)
- [x] 2.1 Write integration tests (sun follows the clock, key bindings, facing a door, prompt, save round trips, background jobs); verify they fail
- [x] 2.2 Implement `GameSession`, `Interaction`, `BackgroundJobs`, the interact action, door targets, HUD prompt, main scene wiring; verify they pass

## 3. Integration
- [x] 3.1 Run `scripts/test.sh` and `openspec validate --all --strict`
