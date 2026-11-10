extends GutTest
## Spec traversal-tools: Grapple (in a bare scene), Scanner and flares (on a small world).

var root: Node3D
var player: Player
var jobs: JobManager
var tools: TraversalTools


func _bare_scene() -> void:
	root = Node3D.new()
	player = Player.new()
	player.name = "Player"
	player.input_enabled = false
	player.start_mode = Player.Mode.WALK
	root.add_child(player)
	jobs = JobManager.new()
	jobs.name = "JobManager"
	root.add_child(jobs)
	tools = TraversalTools.new()
	tools.name = "TraversalTools"
	root.add_child(tools)
	tools.player_path = NodePath("../Player")
	tools.jobs_path = NodePath("../JobManager")
	add_child_autofree(root)


## A 4 m tall wall whose near face is `distance` metres in front of the eyes (yaw 0 looks along -z).
func _wall(distance: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 4, 2)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0, WalkModel.EYE_HEIGHT, -distance - 1.0)
	root.add_child(body)


func test_within_and_beyond_reach() -> void:
	_bare_scene()
	jobs.tools["grapple"] = 1
	player.set_view(0.0, 0.0)
	_wall(22.0)
	await wait_physics_frames(3)
	assert_false(tools.grapple())
	assert_almost_eq(Vector2(player.global_position.x, player.global_position.z), Vector2.ZERO, Vector2.ONE * 0.01)
	_wall(18.0)
	await wait_physics_frames(3)
	assert_true(tools.grapple())
	assert_almost_eq(player.global_position.z, -17.6, 0.05)


func test_no_grapple_without_the_tool() -> void:
	_bare_scene()
	_wall(5.0)
	await wait_physics_frames(3)
	assert_false(tools.grapple())
