# Infinite City — notes for contributors and coding agents

Godot 4.7 game, statically typed GDScript, developed spec-first with OpenSpec and test-first with GUT.

## Commands

```bash
scripts/install-godot.sh        # once: downloads Godot 4.7.2 into .tools/godot/
scripts/test.sh                 # run all GUT tests headless (exit code != 0 on failure)
scripts/test.sh -gselect=hash   # run only test files whose name contains "hash"
scripts/screenshot.sh out.png   # render a frame of the main scene (needs Xvfb)
scripts/screenshot.sh out.jpg --doorway --inside --no-hud   # visit the nearest doorway
openspec list                   # active changes
openspec validate --all --strict
```

## Workflow

1. **Propose** a change with OpenSpec (`/opsx:propose` or `openspec new change <name>`):
   proposal → spec deltas → design → tasks.
2. **Apply** it test-first: for every scenario in the spec delta, write a failing GUT test,
   then the smallest implementation that passes, then refactor.
3. **Archive** it (`openspec archive <name>`) once all tasks are checked and tests are green;
   this merges the spec deltas into `openspec/specs/`.

## Layout

- `src/core/` — pure, deterministic logic (no scene tree). Everything here is unit tested.
- `src/world/` — scene nodes (streaming, rendering, camera, doorways).
- `src/scenes/` — `.tscn` scenes; `main.tscn` is the playable flythrough.
- `test/unit/`, `test/integration/` — GUT tests (`test_*.gd`).
- `openspec/specs/` — the current, archived truth of what the game does.
- `openspec/changes/` — proposed and in-progress changes.

## Rules of thumb

- World content = f(seed, integer coordinates). Never use global RNG state or `randi()` in generation.
- Use `Vector3i` cell/chunk coordinates for identity; render positions are relative to the floating origin.
- Keep scenario names in specs and test names in sync so a reader can trace one to the other.
- Static typing is enforced: untyped declarations (including `for` loop variables) are parse errors.
