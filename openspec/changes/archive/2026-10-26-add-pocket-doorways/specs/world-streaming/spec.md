# Spec Delta

## ADDED Requirements

### Requirement: Streaming focus can differ from the camera
The game SHALL be able to stream around a focus point other than the camera. While the player is
inside a pocket space, the focus SHALL be the doorway the player came through, so the city
around the entrance stays loaded; the floating origin keeps following the camera.

#### Scenario: City stays loaded while inside
- **WHEN** the player is inside a pocket space and streaming updates continue
- **THEN** the chunk containing the entrance doorway and every chunk of its streaming region stay loaded

#### Scenario: Origin follows the camera
- **WHEN** the player is inside a pocket space 12 km from the entrance
- **THEN** the camera is within 512 m of the scene origin on every axis
