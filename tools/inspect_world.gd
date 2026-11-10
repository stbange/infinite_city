extends SceneTree
## Prints a seed's generated history: `scripts/godot.sh --headless --path . -s tools/inspect_world.gd -- [seed] [reach x,y,z]`


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var config := CityConfig.new()
	if args.size() > 0:
		config.world_seed = int(args[0])
	var reach := Vector3i(0, -1, 0)
	if args.size() > 1:
		var parts := args[1].split(",")
		reach = Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
	var chronicle := CityChronicle.new(config)
	var history := chronicle.history
	print("== City history, seed %d ==" % config.world_seed)
	for era in history.eras:
		print("  %3d-%3d  %s" % [era.start_year, era.end_year, era.name])
	print("== Powers ==")
	for p in history.powers:
		print("  %s  %-10s %-34s %s" % [p.key, p.type, p.name, p.good])
	print("  war against %s, %s" % [history.power(history.war_antagonist).name,
			"the districts won" if history.war_won_by_districts else "the company won"])
	print("== Legends ==")
	for legend in history.legends:
		print("  %3d  %s%s" % [legend.event.year, legend.event.text, "  (alive)" if legend.is_alive() else ""])
	var rh := chronicle.reach(reach)
	print("== %s %s: %d factions, %d events ==" % [rh.name, reach, rh.factions.size(), rh.events.size()])
	for f in rh.factions:
		print("  %-14s %-8s %-30s %d-%s" % [f.key, f.type, f.name, f.founded, str(f.dissolved) if f.dissolved >= 0 else ""])
	for e in rh.events:
		print("  %3d  %s" % [e.year, e.text])
	quit()
