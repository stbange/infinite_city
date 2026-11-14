# Design: add-gang-aware-routes

- `CityNav.bridge_penalties[bridge key]` adds metres to the bridge crossing cost in both directions.
  Route hints fill it with every gang-claimed bridge within three cells when avoiding gangs.
- Chasers: `_plan_chase` routes from each chaser's nearest node to the courier's (box of one cell,
  6,000 nodes); the movement step spends the chaser's speed along the path points, then heads
  straight for the courier.
