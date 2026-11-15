extends SceneTree
## Renders a lineup of real residents of all ages under a corridor light (developer tool):
## scripts/godot.sh --path . --rendering-method gl_compatibility -s tools/people_lineup.gd -- out.png

var _frames := 0
var _agents: Array[PersonAgent] = []
var _out := ""


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "lineup.png"
	var population: Population = load("res://test/support/shared_city.gd").population()
	var spawn := SpawnFinder.find_on_foot(population.layout)
	var chosen: Array[PersonInfo] = []
	var wanted: Array[int] = [5, 9, 15, 24, 31, 38, 47, 58, 69, 82]
	for dx: int in range(-4, 5):
		for dz: int in range(-4, 5):
			var block := population.layout.block_at(spawn.cell + Vector3i(dx, 0, dz))
			if block == null or block.kind != BlockTypes.Kind.HOUSING:
				continue
			var bp := population.block_people(block)
			for i: int in bp.size():
				var p := population.person(bp.ids[i])
				for w: int in wanted:
					if absi(p.age - w) <= 2 and chosen.filter(func(c: PersonInfo) -> bool: return absi(c.age - w) <= 2).is_empty():
						chosen.append(p)
	chosen.sort_custom(func(a: PersonInfo, b: PersonInfo) -> bool: return a.age < b.age)
	var root := Node3D.new()
	get_root().add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.08, 0.085, 0.095)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.3, 0.3, 0.32)
	env.environment.ambient_light_energy = 0.6
	root.add_child(env)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(40, 40)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.22, 0.22, 0.23)
	floor_mesh.material_override = fm
	root.add_child(floor_mesh)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	light.light_energy = 1.1
	light.shadow_enabled = true
	root.add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 3.5, 3)
	fill.omni_range = 12
	fill.light_color = Color(1.0, 0.85, 0.65)
	root.add_child(fill)
	var n := chosen.size()
	for i: int in n:
		var agent := PersonAgent.new(FigureLook.of(chosen[i], population.world_seed()))
		root.add_child(agent)
		agent.position = Vector3((i - (n - 1) * 0.5) * 0.85, 0, 0)
		agent.rotation.y = PI + (0.5 if i % 3 == 0 else (-0.4 if i % 3 == 1 else 0.0))
		agent.set_activity("working" if i % 4 == 2 else "at home")
		_agents.append(agent)
		print("%d %s %s %.2f m" % [chosen[i].age, chosen[i].pronoun, chosen[i].skill, agent.look.height])
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.3, 5.0)
	cam.rotation_degrees = Vector3(-7, 0, 0)
	cam.fov = 60
	root.add_child(cam)
	cam.current = true


func _process(delta: float) -> bool:
	_frames += 1
	# Every other figure walks on the spot (moved forward) so the gait shows.
	for i: int in _agents.size():
		if i % 2 == 1 and _frames < 9:
			_agents[i].global_position += _agents[i].global_basis.z * -0.06
		_agents[i].animate(0.05)
	if _frames == 9:
		get_root().get_texture().get_image().save_png(_out)
		return true
	return false
