# Proposal: add-music-and-sound

## Why

M18: the game had a hum and nothing else. Chases and scenes need their own sound.

## What Changes

- **Music layers** generated on the fly beside the ambience: a driving pulse while a gang chases,
  a soft chord under story scenes (the chase wins when both happen). Recorded sound and music are
  not part of this change; there are no audio assets yet.

## Capabilities

### Modified Capabilities
- `release-candidate`: sound.

## Impact

- `Ambience.music_for`, pulse and drone layers; encounter and panel paths; tests.
