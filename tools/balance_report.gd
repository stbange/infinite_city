extends SceneTree
## Prints what a day of steady deliveries earns on a few seeds (spec economy-tables / Balance report).
## Usage: scripts/godot.sh --headless --path . -s res://tools/balance_report.gd


func _init() -> void:
	for seed_value: int in [1337, 2024, 77]:
		var config := CityConfig.new()
		config.world_seed = seed_value
		var population := Population.new(CityLayout.new(config), null)
		var start := StartScenario.find(population, SpawnFinder.find_on_foot(population.layout).cell)
		if start.is_empty():
			print("seed %d: no start" % seed_value)
			continue
		var sim := BalanceSim.new(population)
		var day := GameClock.new_game().day_number() * GameClock.MINUTES_PER_DAY
		var stats := sim.play(start["patron"], day + 7 * 60, day + 23 * 60)
		print("seed %d: %d deliveries, ¤%d (tips ¤%d), %.0f m walked, %.1f game min per delivery, %.0f real min; rent ¤%d/week" % [
			seed_value, stats["deliveries"], stats["earnings"], stats["tips"], stats["metres"],
			stats["minutes_per_delivery"], stats["real_minutes"], Wallet.RENT])
	quit()
