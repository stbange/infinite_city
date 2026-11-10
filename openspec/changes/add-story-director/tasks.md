## 1. Director

- [x] 1.1 Write `test/unit/test_story_director.gd` (casting, determinism, no dead ends, slots); verify they fail
- [x] 1.2 Implement `StoryState`, `StoryDirector`, the plot data table; verify they pass

## 2. Runner and dialogue

- [x] 2.1 Write `test/integration/test_story_runner.gd` (acts 1–2, saved story, picking a choice); verify they fail
- [x] 2.2 Implement `StoryRunner`, `DialoguePanel`, `JobManager.delivered`, HUD objective, main scene; verify they pass
- [ ] 2.3 Run `scripts/test.sh` and `openspec validate --all --strict`
