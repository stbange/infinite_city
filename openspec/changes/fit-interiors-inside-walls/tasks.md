# Tasks

## 1. Fit floors and stairs inside the walls (spec: block-interiors)

- [x] 1.1 Add "Slabs within the inner footprint", "Closed façade", "Nothing fights for a surface" and "Stair core inside its unit" to `test/unit/test_interior_floor.gd` / `test/unit/test_interior_plan.gd`; verify they fail
- [x] 1.2 Slabs and the roof slab on `plan.inner`, floor 0 walls and shell down to the slab bottom, stair core on the wall's inner face in `InteriorLayout`; verify `-gselect=interior` passes

## 2. Visual check and integration

- [x] 2.1 Render an entrance and a stairwell; verify by eye that floor lines and stairs no longer flicker
- [x] 2.2 Run `scripts/test.sh` (all green) and `openspec validate --all --strict`
