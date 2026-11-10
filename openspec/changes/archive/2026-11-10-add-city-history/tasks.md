# Tasks

## 1. City history (spec: city-history)
- [x] 1.1 Write `test/unit/test_city_history.gd` (era sequence, powers, legends, influence) ; verify it fails
- [x] 1.2 Implement `CityHistory`, `EraInfo`, `FactionInfo`, `LegendInfo`, `HistoryEvent`, `InfluenceField`, data tables; verify it passes

## 2. Reach histories (spec: city-history)
- [x] 2.1 Write `test/unit/test_reach_history.gd` (living factions, consistent events, things happen, territory, order, border feuds, time budget); verify it fails
- [x] 2.2 Implement `ReachHistory`, `Territory`, `CityChronicle`; verify it passes

## 3. Integration
- [x] 3.1 Run `scripts/test.sh` and `openspec validate --all --strict`
