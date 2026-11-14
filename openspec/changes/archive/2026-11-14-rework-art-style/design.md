# Design: rework-art-style

- Functional colours stay in the data (`BlockTypes.color`, sign colours, furniture colours) so the
  legend, tests and history keep their meaning; drawing applies the style: the block shader mixes
  only 4% of the function colour into facades and uses it only for the rare tinted window; signs and
  interior items pass through `mute()` when their instance buffers are written.
- `mute(color, keep)` keeps the hue, scales the saturation by `keep` and dims slightly
  (0.35 for accents, 0.5 for furniture).
- Shadows use the engine's: block lighting is a custom `light()` that multiplies by `ATTENUATION`,
  which includes the shadow, so blocks shadow each other without shader changes.
- The grade lives in the main scene's environment and must match `ArtStyle.GRADE_*` (tested).
