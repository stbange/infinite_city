## 1. Rules

- [x] 1.1 Write `test/unit/test_progression.gd` (levels, licence upgrade, tiers, shop rules); verify they fail
- [x] 1.2 Implement `Reputation`, `Licence`, `CargoKind`, `ShopCatalogue`, board tiers; verify they pass

## 2. In the game

- [x] 2.1 Write `test/integration/test_courier_shop.gd` (buying, gangs remember); verify they fail
- [x] 2.2 Implement progression state in `JobManager`, `CourierShop`, encounter reputation, HUD; verify they pass
- [ ] 2.3 Run `scripts/test.sh` and `openspec validate --all --strict`
