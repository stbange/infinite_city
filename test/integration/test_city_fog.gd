extends GutTest
## Spec city-fog: Fog by height, Sunlit haze, Drifting fog banks, Clear air indoors, One fog for
## every camera (on the main scene and on a small world with an entered block).

const MAIN_SCENE := "res://src/scenes/main.tscn"
const EPS := 1e-4


func _main() -> Node3D:
	var main := (load(MAIN_SCENE) as PackedScene).instantiate() as Node3D
	add_child_autofree(main)
	await wait_process_frames(3)
	return main


func _color(value: Variant) -> Color:
	return value as Color if value is Color else Color((value as Vector3).x, (value as Vector3).y, (value as Vector3).z)


func test_the_shader_follows_the_same_rule() -> void:
	var main := await _main()
	var world := main.get_node("CityWorld") as CityWorld
	(main.get_node("CityFog") as CityFog).refresh()
	var fog := CityFog.material()
	var depth := world.focus_depth_layers()
	assert_almost_eq(float(fog.get_shader_parameter("density_below")), Atmosphere.below_density(depth), EPS)
	assert_almost_eq(float(fog.get_shader_parameter("density_above")), Atmosphere.ABOVE_DENSITY, EPS)
	assert_almost_eq(float(fog.get_shader_parameter("clear_layers")), Atmosphere.CLEAR_LAYERS, EPS)
	assert_almost_eq(float(fog.get_shader_parameter("sea_depth")), Atmosphere.FOG_SEA_DEPTH, EPS)
	assert_almost_eq(float(fog.get_shader_parameter("sea_band")), Atmosphere.FOG_SEA_BAND, EPS)
	assert_almost_eq(float(fog.get_shader_parameter("layer_height")), world.config.cell_size.y, EPS)
	var bottom := world.origin.scene_position_of_cell(Vector3i(0, world.config.roof_layer, 0)).y
	var top := world.origin.scene_position_of_cell(Vector3i(0, world.config.roof_layer + 1, 0)).y
	assert_almost_eq(float(fog.get_shader_parameter("roof_bottom_y")), bottom, EPS)
	assert_almost_eq(float(fog.get_shader_parameter("roof_top_y")), top, EPS)


func test_haze_colour() -> void:
	var main := await _main()
	var world := main.get_node("CityWorld") as CityWorld
	(main.get_node("CityFog") as CityFog).refresh()
	var fog := CityFog.material()
	var depth := world.focus_depth_layers()
	assert_true(_color(fog.get_shader_parameter("sun_haze")).is_equal_approx(Atmosphere.SUN_HAZE))
	assert_almost_eq(float(fog.get_shader_parameter("sun_fade")), Atmosphere.SUN_FADE_M, EPS)
	assert_true(_color(fog.get_shader_parameter("color_below")).is_equal_approx(Atmosphere.below_color(depth)))
	assert_true(_color(fog.get_shader_parameter("color_above")).is_equal_approx(Atmosphere.ABOVE_FOG))


func test_banks_and_wind() -> void:
	var fog := CityFog.material()
	assert_gt(float(fog.get_shader_parameter("bank_strength")), 0.0)
	assert_gt((fog.get_shader_parameter("wind") as Vector3).length(), 0.0)


func test_no_double_fog() -> void:
	var main := await _main()
	var env := (main.get_node("WorldEnvironment") as WorldEnvironment).environment
	assert_false(env.fog_enabled)
	var fog := main.get_node("CityFog") as CityFog
	fog.refresh()
	var player := main.get_node("Player") as Player
	assert_not_null(fog.quad())
	assert_eq(fog.quad().get_parent(), player.camera)
	assert_eq(fog.quad().layers, RenderLayers.FOG)
	assert_eq(fog.quad().material_override, CityFog.material())


func _enter_pocket(main: Node3D) -> PocketManager:
	var world := main.get_node("CityWorld") as CityWorld
	var manager := main.get_node("PocketManager") as PocketManager
	var doorway := ScreenshotCapture.showcase_doorway(world, Vector3i(0, 0, 0))
	manager.place_camera_before(doorway, 20.0)
	for i in 40:
		world.tick()
	manager.update()
	return manager


func test_outside() -> void:
	var main := await _main()
	var manager := _enter_pocket(main)
	assert_not_null(manager.active_doorway())
	assert_false(manager.is_inside())
	(main.get_node("CityFog") as CityFog).refresh()
	var player := main.get_node("Player") as Player
	assert_true(player.camera.get_cull_mask_value(RenderLayers.FOG_LAYER_NUMBER))
	assert_eq(manager.portal_camera().cull_mask & RenderLayers.FOG, 0)


func test_inside_a_pocket_space() -> void:
	var main := await _main()
	var manager := _enter_pocket(main)
	manager.enter()
	manager.update()
	assert_true(manager.is_inside())
	(main.get_node("CityFog") as CityFog).refresh()
	var player := main.get_node("Player") as Player
	assert_false(player.camera.get_cull_mask_value(RenderLayers.FOG_LAYER_NUMBER))
	var portal := manager.portal_camera().cull_mask
	assert_eq(portal & RenderLayers.FOG, RenderLayers.FOG)
	assert_eq(portal & RenderLayers.CITY, RenderLayers.CITY)
	assert_eq(portal & RenderLayers.INTERIOR, RenderLayers.INTERIOR)


func test_clear_inside_an_entered_block() -> void:
	var world := CityWorld.new()
	world.config = CityConfig.new()
	world.radius_h = 1
	world.radius_v = 1
	world.auto_tick = false
	var player := Player.new()
	player.name = "Player"
	player.input_enabled = false
	player.start_mode = Player.Mode.FLY
	world.add_child(player)
	world.focus_path = NodePath("Player")
	var manager := InteriorManager.new()
	manager.name = "InteriorManager"
	manager.auto_update = false
	world.add_child(manager)
	manager.world_path = NodePath("..")
	manager.player_path = NodePath("../Player")
	var fog := CityFog.new()
	fog.name = "CityFog"
	world.add_child(fog)
	fog.world_path = NodePath("..")
	fog.camera_path = NodePath("../Player")
	fog.interiors_path = NodePath("../InteriorManager")
	add_child_autofree(world)
	var block: BlockInfo = null
	for x in range(-20, 20):
		var candidate := world.layout.block_at(Vector3i(x, -2, 3))
		if candidate != null and candidate.size.y >= 12.0:
			block = candidate
			break
	assert_not_null(block)
	var absolute := PackedFloat64Array()
	var inside := Vector3(0.0, block.min_local().y + 4.05, 0.0)  # floor 1 at the corridor crossing
	for axis in 3:
		absolute.append((block.cell[axis] + 0.5) * world.config.cell_size[axis] + inside[axis])
	world.teleport_focus(absolute)
	world.prime_focus()
	for i in 40:
		manager.update()
	var view := manager.view_for(block.cell)
	assert_not_null(view)
	assert_true(view.is_ready())
	fog.refresh()
	var centre := world.origin.scene_position_of_cell_center(block.cell)
	var expected := AABB(centre + block.min_local() - Vector3(0, InteriorLayout.SLAB, 0),
			block.size + Vector3(0, InteriorLayout.SLAB, 0))
	var boxes := fog.clear_boxes()
	assert_eq(boxes.size(), 1)
	assert_true(boxes[0].is_equal_approx(expected), "%s vs %s" % [boxes[0], expected])
	var material := CityFog.material()
	assert_true((material.get_shader_parameter("clear_min_0") as Vector3).is_equal_approx(expected.position))
	assert_true((material.get_shader_parameter("clear_max_0") as Vector3).is_equal_approx(expected.end))
