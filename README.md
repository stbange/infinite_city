# Infinite City

A science-fiction city of floating blocks in space, built with **Godot 4.7**. The city has exactly
one border, its roof. Above it float a few stray blocks, and beyond them there is only a single
light source. Downward and to every side the city never ends. Canyons and shafts open it up for
travel in every direction, bridges join neighbouring blocks, and some doors open into spaces far
bigger than the blocks that hold them.

| Above the roof | Up a shaft to the light |
|---|---|
| ![Roof](docs/images/roof.jpg) | ![Shaft](docs/images/shaft-light.jpg) |
| **Inside a canyon, 20 layers down** | **640,000 km down: same precision** |
| ![Canyon](docs/images/canyon.jpg) | ![Deep](docs/images/deep.jpg) |
| **A doorway on a market block…** | **…opens into a 207 × 79 × 288 m bazaar** |
| ![Doorway outside](docs/images/doorway-outside.jpg) | ![Doorway inside](docs/images/doorway-inside.jpg) |
| **Looking back out at the city from inside** | |
| ![Look back](docs/images/doorway-look-back.jpg) | |

All images are rendered headless by `scripts/screenshot.sh` with software OpenGL, so the real
game looks crisper.

## Can this be done? Yes, and here is how

### 1. "Terrain" generation for an infinite city

The city is not a heightmap. It is a **3D lattice of 64 m cells**, and every cell answers
"what is here?" as a **pure function of (seed, integer coordinates)**:

- **Deterministic hashing** (MurmurHash3 on 32-bit words, made overflow-safe for GDScript's
  64-bit ints) instead of noise or global random state. Any region can be generated in any
  order, on any machine, with identical results. Golden values are pinned by tests.
- **One border:** above roof layer `R` there are 4 sparse sky layers, thinning upward, and
  nothing beyond them. Below and sideways the lattice covers the full 32-bit coordinate range.
- **Canyons that go on forever** come from integer rules per district (8×8×8 cells), so they
  stay continuous without needing their neighbours. Vertical shafts depend only on the district
  column (x, z), and X/Z canyons depend only on the district row. Plazas add local open space.
- **A real city:** blocks are housing, farms, markets, offices, industry and parks, with a mix
  that changes with depth (farms and industry deep down, markets and offices near the roof).
  Every district has exactly one hospital, fire station, security station, school, power
  plant, water works and transit hub.
- **Streaming:** 4×4×4-cell chunks (~2 ms each in GDScript) load nearest first in an ellipsoid
  around the player, with a per-frame budget.
- **Floating origin:** float32 positions lose precision kilometres from the origin. So all scene
  positions are relative to an *integer* origin chunk that follows the camera. Precision at
  10 million layers down is the same as at the roof (see the deep screenshot).

### 2. Magic doorways (bigger on the inside)

- **Doorways are transform pairs.** The outer door A sits on a block; the inner door B sits on
  the wall of the pocket space. A pose is carried through with `M = B · R_y(π) · A⁻¹`, so what is
  in front of one door continues behind the other.
- **The interior lives out of sight, 12 km above its door** and is drawn on its own visual
  layer. It can be any size (here 160–320 m wide, 60–140 m high, 240–480 m deep) behind a 4 m
  door on a ~50 m block.
- **Live view:** a second camera in a `SubViewport` takes `M · camera`. The door surface shows
  its image at `SCREEN_UV`. Its near plane is clipped at the far door, so walls in between
  never block the view.
- **Seamless crossing:** when the camera crosses the door plane from the front, inside the
  opening, it is moved through `M` in the same frame, keeping position, view direction and
  speed. Crossing from behind does nothing. The city around the entrance stays loaded while
  you are inside, so stepping out again is instant.
- **Teleporters** are the easier cousin: an instant jump plus a floating-origin rebase. That is
  the next proposed change (see the roadmap).

## Running it

1. Install **Godot 4.7.2** (standard build, GDScript only), or run `scripts/install-godot.sh`
   on Linux.
2. Open the project folder in Godot and press **Play**, or run `godot --path .`.

Controls: **click** to look around, **WASD** to fly, **Space/E** up, **Q/Ctrl** down,
**Shift** boost, **mouse wheel** changes speed, **Esc** releases the mouse. You start at the rim
of a shaft. Fly towards any glowing violet doorway and straight through it.

## How it is developed: OpenSpec + test-driven development

Every feature goes through [OpenSpec](https://github.com/Fission-AI/OpenSpec):

1. **Propose:** `openspec/changes/<name>/` gets a proposal, spec deltas (requirements with
   testable scenarios), a design and a task list. Ordered test-first.
2. **Apply:** each scenario becomes a failing [GUT](https://github.com/bitwes/Gut) test, then the
   smallest implementation that passes it.
3. **Archive:** the spec deltas merge into `openspec/specs/`, which always describes what the
   game does today.

Git history follows this rhythm (*Propose → Implement → Archive*) for each change:

| Change | Capabilities (in `openspec/specs/`) |
|---|---|
| `add-city-generation` | `city-layout`, `city-zoning`, `city-bridges` |
| `add-world-streaming` | `world-streaming`, `floating-origin`, `city-rendering`, `free-flight` |
| `add-pocket-doorways` | `pocket-doorways`, `pocket-spaces`, `portal-traversal` |

```bash
scripts/install-godot.sh              # once: Godot 4.7.2 into .tools/godot/
scripts/test.sh                       # 189 GUT tests, headless (~25 s)
scripts/test.sh -gselect=portal       # only test files matching "portal"
scripts/screenshot.sh out.png --doorway --inside   # headless render (needs Xvfb)
openspec list --specs                 # current capabilities
openspec validate --all --strict      # spec hygiene (also run in CI)
```

Pure logic lives in `src/core/` (no scene tree, fully unit-tested). Scene nodes live in
`src/world/` (integration-tested). GitHub Actions runs the GUT suite and strict OpenSpec
validation on every push. Static typing is enforced, so untyped declarations are parse errors.

## Roadmap (next OpenSpec changes)

1. **`add-teleport-network`**: transit hubs (one per district) linked to neighbouring hubs and
   to express hubs far above and below. Instant jumps with a rebase.
2. **`add-flying-traffic`**: lanes through gaps, canyons and shafts. Cars placed by
   `f(lane, time)`, so traffic is deterministic and only simulated near the player.
3. **`add-on-foot-movement`**: collision for blocks and bridges near the player, walking and
   gravity, entering doorways on foot.
4. **`add-city-connections`**: long-span bridges across canyons, lifts and stairs between layers.
5. **`add-block-interiors`**: ordinary interiors (homes, farms, hospitals) and services that
   work: fire stations dispatch, hospitals treat.
6. **Performance:** chunk generation on worker threads, level of detail beyond the streaming
   radius, lower-resolution portal views.
7. **Gameplay:** what the player *does* in the city. A story, jobs, exploration goals. This is
   the big open design question.

## Known limitations of this prototype

- The player is a free-flying spectator: no collision yet.
- One live portal at a time. Other doorways shimmer until you are within 160 m.
- There are no shadows from the light source, because the area is too large. Depth is
  conveyed by an atmosphere that darkens and by lit windows instead.
