# Proposal: add-courier-progression

## Why

M8 of the Fogline plan: growth. Noodle runs should lead somewhere — better cargo, better pay,
standing with the factions, tools to move through the city.

## What Changes

- **Reputation** per faction (−100 … 100) with levels hostile, wary, neutral, friendly, trusted.
  Deliveries raise standing with the Couriers' Mutual; paying a gang's toll raises standing with
  it, running and being caught lower it. Trusted gangs wave the courier through; friendly gangs ask
  less.
- **Licences** from the Mutual: bronze (start), silver (Mutual 30, ¤150), gold (Mutual 80, ¤400).
  A licence sets the highest cargo tier the courier may carry.
- **Cargo tiers:** food (tier 1); parcels and medicine (tier 2, better pay); contraband and data
  (tier 3, best pay, and gangs take more interest). With a higher licence, some of the counter's
  orders are higher-tier cargo.
- **Shop:** the scanner, flares, the glider and the grapple, each with a price and the licence it
  needs; plus the licence upgrade. Opened with U, bought with the number keys.

## Capabilities

### New Capabilities
- `courier-progression`: reputation, licences, cargo tiers and the shop.

## Impact

- New `src/core/reputation.gd`, `licence.gd`, `cargo_kind.gd`, `shop_catalogue.gd`,
  `src/world/courier_shop.gd`; `CourierBoard.offers(..., max_tier)`; `DeliveryJob.cargo_kind`;
  progression state in `JobManager` (saved); reputation in `EncounterDirector`; `DialoguePanel`
  keys 1–9; tests `test/unit/test_progression.gd`, `test/integration/test_courier_shop.gd`.
