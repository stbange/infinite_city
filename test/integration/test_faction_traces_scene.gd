extends GutTest
## Spec faction-traces: Ruins are drawn, Turf read-out, Debug timeline.


func test_ruins_are_drawn() -> void:
	var config := CityConfig.new()
	var world := CityWorld.new()
	world.config = config
	world.auto_tick = false
	var focus := Node3D.new()
	focus.name = "Focus"
	world.add_child(focus)
	focus.add_to_group(CityWorld.ANCHORED_GROUP)
	world.focus_path = NodePath("Focus")
	add_child_autofree(world)
	var traces := TraceLayout.new(world.chronicle, world.layout)
	var found := Vector3i.ZERO
	var searching := true
	var rng := CellRandom.new(8)
	while searching:
		var cell := Vector3i(rng.range_int(-200, 200), -rng.range_int(10, 150), rng.range_int(-200, 200))
		if world.layout.is_solid(cell) and traces.is_ruined(cell):
			found = cell
			searching = false
	var chunk := world.layout.chunk_of(found)
	world.teleport_focus(PackedFloat64Array([found.x * 64.0, found.y * 64.0, found.z * 64.0]))
	world.prime_focus()
	var view := world.chunk_view(chunk)
	assert_not_null(view)
	var seen_ruin := false
	for i in view.block_count():
		var block := view.blocks()[i]
		var flag := view.block_custom(i).b
		assert_eq(flag > 0.5, traces.is_ruined(block.cell), "block %s" % block.cell)
		if block.cell == found:
			seen_ruin = flag > 0.5
	assert_true(seen_ruin)


func test_read_out_names_the_turf() -> void:
	var main := (load("res://src/scenes/main.tscn") as PackedScene).instantiate() as Node3D
	add_child_autofree(main)
	await wait_process_frames(2)
	var world := main.get_node("CityWorld") as CityWorld
	var hud := main.get_node("Hud") as Hud
	hud.refresh()
	var player := main.get_node("Player") as Player
	var district := world.layout.district_of(world.origin.absolute_cell_of(player.global_position - Vector3(0, 0.1, 0)))
	var owner := world.chronicle.faction(world.chronicle.owner_of_district(district))
	assert_string_contains(hud.text(), "Turf: " + owner.name)
	assert_string_contains(hud.text(), world.chronicle.reach(CityChronicle.reach_of(district)).name)


func test_timeline_panel() -> void:
	var main := (load("res://src/scenes/main.tscn") as PackedScene).instantiate() as Node3D
	add_child_autofree(main)
	await wait_process_frames(2)
	var world := main.get_node("CityWorld") as CityWorld
	var hud := main.get_node("Hud") as Hud
	hud.set_debug_visible(true)
	hud.refresh()
	var player := main.get_node("Player") as Player
	var district := world.layout.district_of(world.origin.absolute_cell_of(player.global_position - Vector3(0, 0.1, 0)))
	var reach := world.chronicle.reach(CityChronicle.reach_of(district))
	assert_string_contains(hud.debug_text(), reach.name)
	assert_string_contains(hud.debug_text(), reach.events[-1].text)
