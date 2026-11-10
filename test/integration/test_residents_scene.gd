extends GutTest
## Spec residents: Door plates and residents card. Spec workplaces: Job market budget (prefetch).

var world: CityWorld
var player: Player
var manager: InteriorManager
var interaction: Interaction
var hud: Hud


func before_each() -> void:
	world = CityWorld.new()
	world.config = CityConfig.new()
	world.radius_h = 1
	world.radius_v = 1
	world.auto_tick = false
	player = Player.new()
	player.name = "Player"
	player.input_enabled = false
	player.start_mode = Player.Mode.FLY
	world.add_child(player)
	world.focus_path = NodePath("Player")
	manager = InteriorManager.new()
	manager.name = "InteriorManager"
	manager.auto_update = false
	world.add_child(manager)
	manager.world_path = NodePath("..")
	manager.player_path = NodePath("../Player")
	interaction = Interaction.new()
	interaction.name = "Interaction"
	world.add_child(interaction)
	interaction.player_path = NodePath("../Player")
	interaction.interiors_path = NodePath("../InteriorManager")
	add_child_autofree(world)
	hud = Hud.new()
	add_child_autofree(hud)
	hud.world_path = hud.get_path_to(world)
	hud.camera_path = hud.get_path_to(player)
	hud.interaction_path = hud.get_path_to(interaction)


## Faces the door of a non-core unit on floor index 1 of the first block of `kind` found.
func _face_door(kind: int, occupied: bool) -> Dictionary:
	var population := world.population
	for x in range(-30, 30):
		for z: int in [3, -5, 9]:
			var block := world.layout.block_at(Vector3i(x, -2, z))
			if block == null or block.kind != kind:
				continue
			var plan := population.plan_of(block)
			for unit in plan.units:
				if unit.is_core:
					continue
				if occupied and population.household(block.cell, 1, unit.index).is_vacant():
					continue
				var local := Vector3(unit.door_x, plan.floor_y(1) + 0.02, unit.front_z() + unit.front_sign * 1.5)
				var absolute := PackedFloat64Array()
				for axis in 3:
					absolute.append((block.cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
				world.teleport_focus(absolute)
				player.set_view(0.0 if unit.front_sign > 0 else PI, 0.0)
				world.prime_focus()
				for i in 40:
					manager.update()
				interaction.refresh()
				return {"block": block, "unit": unit.index}
	return {}


func test_flat_label_names_the_household() -> void:
	var found := _face_door(BlockTypes.Kind.HOUSING, true)
	assert_false(found.is_empty())
	var block: BlockInfo = found["block"]
	var residents := world.population.residents(block.cell, 1, found["unit"])
	var label := str(interaction.target().get("label", ""))
	assert_string_contains(label, residents[0].family_name)
	assert_string_contains(label, "Fl 2")


func test_workplace_label_names_the_business() -> void:
	var found := _face_door(BlockTypes.Kind.OFFICE, false)
	if found.is_empty():
		found = _face_door(BlockTypes.Kind.MARKET, false)
	assert_false(found.is_empty())
	var block: BlockInfo = found["block"]
	var workplace := world.population.workplace(block.cell, 1, found["unit"])
	assert_string_contains(str(interaction.target().get("label", "")), workplace.name)


func test_residents_card() -> void:
	var found := _face_door(BlockTypes.Kind.HOUSING, true)
	var block: BlockInfo = found["block"]
	interaction.interact()
	var card := hud.card_text()
	for p in world.population.residents(block.cell, 1, found["unit"]):
		assert_string_contains(card, p.full_name())


func test_door_plates_near_the_player() -> void:
	var found := _face_door(BlockTypes.Kind.HOUSING, true)
	var block: BlockInfo = found["block"]
	var view := manager.view_for(block.cell)
	assert_not_null(view)
	var plates := view.plate_texts()
	assert_gt(plates.size(), 0)
	var residents := world.population.residents(block.cell, 1, found["unit"])
	assert_has(plates, residents[0].family_name)


func test_prefetch_builds_the_market_in_the_background() -> void:
	var district := world.layout.district_of(world.origin.absolute_cell_of(player.global_position))
	world.prefetch_job_market(district)
	for i in 600:
		world.poll_background()
		if world.population.has_job_market(district):
			break
		await wait_process_frames(1)
	assert_true(world.population.has_job_market(district))
