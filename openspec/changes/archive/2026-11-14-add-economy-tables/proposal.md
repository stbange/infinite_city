# Proposal: add-economy-tables

## Why

M11 of draft 2 of the plan: before new features, the game must be played and tuned. Every number
that decides how the loop feels was a constant in code and had never been checked against play.

## What Changes

- **Economy table:** pay, tips and cooling, rent and starting credits, tolls and chases, the rescue
  fee, shop and licence prices, and live-simulation drift move to `data/economy.json`; rules read
  it at call time, and single values can be overridden for tuning and tests.
- **Balance report:** a scripted courier plays the counter's orders over real walking routes and
  reports deliveries, earnings, tips and time per delivery (`tools/balance_report.gd`). The first
  report showed a day earning ¤1,600 against ¤120 rent and no tips; the table is tuned to about
  ¤440 a day against ¤900 a week, with tips around 15%.
- **Session stats (F4):** orders, deliveries and earnings per game hour, tolls, rescues and average
  delivery time for real playtests, plus a play sheet in `docs/playtest-sheet.md`.

## Capabilities

### New Capabilities
- `economy-tables`: the economy table, the balance report and session stats.

## Impact

- New `data/economy.json`, `src/core/economy.gd`, `balance_sim.gd`, `play_stats.gd`,
  `tools/balance_report.gd`; constants become table-backed static properties; tests read the table.
