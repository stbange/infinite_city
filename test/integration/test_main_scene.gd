extends GutTest
## Specs city-rendering (Light source above the roof) and free-flight (Starting point,
## Location read-out) on the playable main scene.

const MAIN_SCENE := "res://src/scenes/main.tscn"

var main: Node3D


func before_each() -> void:
	main = (load(MAIN_SCENE) as PackedScene).instantiate() as Node3D
	add_child_autofree(main)
	await wait_process_frames(2)


func _world() -> CityWorld:
	return main.get_node("CityWorld") as CityWorld


func _camera() -> FlyCamera:
	return main.get_node("FlyCamera") as FlyCamera


func test_exactly_one_downward_light() -> void:
	var lights := main.find_children("*", "DirectionalLight3D", true, false)
	assert_eq(lights.size(), 1)
	var light := lights[0] as DirectionalLight3D
	var direction := -light.global_transform.basis.z
	assert_lte(direction.y, -0.7, "light should shine down onto the city")


func test_sky_shows_the_light_source() -> void:
	var env := (main.get_node("WorldEnvironment") as WorldEnvironment).environment
	var sky_material := env.sky.sky_material as ShaderMaterial
	assert_not_null(sky_material)
	assert_eq(sky_material.shader.resource_path, "res://src/world/shaders/space_sky.gdshader")


func test_camera_starts_at_the_spawn_point() -> void:
	var world := _world()
	var spawn := SpawnFinder.find(world.layout)
	assert_eq(world.origin.absolute_cell_of(_camera().global_position), spawn.cell)
	assert_almost_eq(_camera().yaw, spawn.yaw, 1e-5)
	assert_almost_eq(_camera().pitch, spawn.pitch, 1e-5)


func test_streaming_runs() -> void:
	await wait_process_frames(5)
	assert_gt(_world().loaded_chunks().size(), 0)


func test_hud_shows_the_read_out() -> void:
	var hud := main.get_node("Hud") as Hud
	hud.refresh()
	assert_string_contains(hud.text(), "Altitude 2 layers above the roof")
	assert_string_contains(hud.text(), "Cell ")


func test_hud_names_the_block_the_camera_is_inside() -> void:
	var world := _world()
	var block: BlockInfo = null
	for x in range(0, 40):
		block = world.layout.block_at(Vector3i(x, -3, 2))
		if block != null:
			break
	assert_not_null(block)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((block.cell[axis] + 0.5) * world.config.cell_size[axis] + block.offset[axis])
	world.teleport_focus(absolute)
	var hud := main.get_node("Hud") as Hud
	hud.refresh()
	assert_string_contains(hud.text(), "Inside: " + BlockTypes.display_name(block.kind))


func test_main_scene_has_a_pocket_manager() -> void:
	var manager := main.get_node("PocketManager") as PocketManager
	assert_not_null(manager)
	var sun := main.get_node("Sun") as DirectionalLight3D
	assert_eq(sun.light_cull_mask & PocketManager.POCKET_LAYERS, 0, "the sun must not light pocket spaces")


func test_hud_shows_the_pocket_read_out_inside() -> void:
	var world := _world()
	var manager := main.get_node("PocketManager") as PocketManager
	var doorway := ScreenshotCapture.showcase_doorway(world, Vector3i(0, 0, 0))
	assert_not_null(doorway)
	manager.place_camera_before(doorway, 20.0)
	for i in 40:
		world.tick()
	manager.update()
	assert_not_null(manager.active_doorway())
	manager.enter()
	assert_true(manager.is_inside())
	var hud := main.get_node("Hud") as Hud
	hud.refresh()
	assert_string_contains(hud.text(), "Pocket space: ")
	assert_string_contains(hud.text(), "behind cell %d, %d, %d" % [doorway.cell.x, doorway.cell.y, doorway.cell.z])
