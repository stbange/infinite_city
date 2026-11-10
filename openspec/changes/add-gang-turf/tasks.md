## 1. Turf and rules

- [x] 1.1 Write `test/unit/test_gang_turf.gd` (claims, determinism, tolls, heat, rolls); verify they fail
- [x] 1.2 Implement `TurfMap`, `Heat`, `EncounterRules`; verify they pass

## 2. Encounters in the world

- [x] 2.1 Write `test/integration/test_encounters.gd` (toll and pay, no cargo, escape, caught); verify they fail
- [x] 2.2 Implement `EncounterDirector`, `JobManager.lose_cargo`, HUD lines, main scene; verify they pass
- [ ] 2.3 Run `scripts/test.sh` and `openspec validate --all --strict`
