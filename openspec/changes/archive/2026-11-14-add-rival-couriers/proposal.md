# Proposal: add-rival-couriers

## Why

M15: waiting at the counter cost nothing. Other couriers should take work that is left lying.

## What Changes

- Each order has a chance (half) of being taken by a rival courier at a minute of the hour between
  :10 and :59; it then disappears from the counter. The HUD counts the orders rivals took this hour.

## Capabilities

### New Capabilities
- `rival-couriers`: rivals taking open orders.

## Impact

- `CourierBoard.rival_minute`; `JobManager.open_orders`, `rivals_this_hour`; `BalanceSim` counts
  rivals; economy `orders.rival_share`.
