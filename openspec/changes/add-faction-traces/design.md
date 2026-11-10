# Design: add-faction-traces

`TraceLayout(chronicle, lighting)` is pure. Damaged districts are those with a `raid` or
`blackout` event. The memorial cell of a district is `district origin + (h % 8, h/8 % 8, h/64 % 8)`
from `hash(seed, SALT_MEMORIAL, district)`. Ruins: `u01(hash(seed, SALT_RUIN, cell)) < 0.25` in
damaged districts. Tags reuse `SignInfo` (solid-pattern neon) placed by `CityLighting.try_sign()`
with a small size and `CityLighting.fits()` against the block's other signs; memorials are white,
non-flickering 6 × 2.5 m signs on the lowest floors. `CityWorld` owns a `CityChronicle`, appends
traces to each block's signs in `_load()` and passes ruin flags to `ChunkView.build()`, which
writes them into `INSTANCE_CUSTOM.z`; `block.gdshader` reduces the lit share to 3% and darkens the
facade there. The HUD reads the district owner through `CityWorld.chronicle`.
