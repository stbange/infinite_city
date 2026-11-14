# Design: add-transit-hubs

- `TransitNetwork.hub_of(district)` finds the district plan's transit-hub cell; `links(district)`
  lists fixed steps, keeping only districts below the sky, so links are symmetric.
- A ride teleports through `CityWorld.teleport_focus` (floating origin, full precision), primes the
  chunks and resets the fall guard to the new ground.
- Routes for hints and figures do not use hubs yet; they stay within a few cells.
