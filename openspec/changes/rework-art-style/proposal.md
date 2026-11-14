# Proposal: rework-art-style

## Why

The city looked like the Matrix: coloured window glow, neon edge strips on every block in every
colour, violet fog, pink and cyan corridors, bright bloom and no shadows. It should look like a city
in space: mostly greys and darkness, lit by warm sodium and cool white light, with colour kept for
small, rare accents, and real shadows.

## What Changes

- **One palette** (`ArtStyle`): facades in dark steel grey, nearly black glass; windows mostly warm,
  some cool white, a few faintly tinted by the block's function; fewer lit windows (13% instead of
  22%); edge strips and bridge rails in dim grey-white; lamps sodium and cool white; corridor lights
  warm and cool whites; fog blue-grey, dark below the fogline; the sky's haze grey.
- **Muted accents:** signs, furniture and lights inside, faction colours and the doorway frames keep
  only part of their saturation (`ArtStyle.mute`), applied when drawn so the data keeps its meaning.
- **Shadows:** the sun casts shadows across the roof (450 m); blocks, bridges, railings, posts and
  interior walls, floors and furniture cast them; the four best pool lights near the player cast
  shadows too.
- **Grade:** the environment desaturates (0.6), adds contrast (1.12) and darkens slightly; glow is
  weaker and only the brightest things bloom; ambient light is neutral grey.

## Capabilities

### New Capabilities
- `art-style`: the palette, muted accents, shadows and the colour grade.

## Impact

- New `src/core/art_style.gd`; `Atmosphere` fog colours; `CityLighting.LAMP_COLORS`;
  `InteriorLayout.CORRIDOR_COLORS`; block, bridge and sky shaders; `ChunkView`, `InteriorView`
  and `CityLights` shadows and muting; `DoorwayView`; main scene environment and sun; tests.
