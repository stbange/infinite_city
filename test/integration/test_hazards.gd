extends GutTest
## Specs hazards (Rescue drone) and flying-traffic (Car hits) on a small world.

var world: CityWorld
var player: Player
var session: GameSession
var jobs: JobManager
var traffic: TrafficManager
var hazards: HazardDirector


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
	session = GameSession.new()
	session.name = "GameSession"
	session.running = false
	world.add_child(session)
	session.world_path = NodePath("..")
	session.player_path = NodePath("../Player")
	jobs = JobManager.new()
	jobs.name = "JobManager"
	world.add_child(jobs)
	jobs.world_path = NodePath("..")
	jobs.session_path = NodePath("../GameSession")
	traffic = TrafficManager.new()
	traffic.name = "TrafficManager"
	traffic.auto_update = false
	world.add_child(traffic)
	traffic.world_path = NodePath("..")
	traffic.session_path = NodePath("../GameSession")
	traffic.player_path = NodePath("../Player")
	hazards = HazardDirector.new()
	hazards.name = "HazardDirector"
	world.add_child(hazards)
	hazards.player_path = NodePath("../Player")
	hazards.jobs_path = NodePath("../JobManager")
	hazards.traffic_path = NodePath("../TrafficManager")
	add_child_autofree(world)
	hazards._connect()


func _carry_one() -> void:
	var job := DeliveryJob.new()
	job.id = "test"
	jobs.carried.append(job)


func test_rescued_after_a_fall() -> void:
	_carry_one()
	jobs.wallet.credits = 100
	player.rescued.emit("fall")
	assert_eq(jobs.wallet.credits, 100 - HazardDirector.FEE)
	assert_eq(jobs.carried.size(), 0)
	assert_string_contains(hazards.last_message, "Rescue drone")


func test_fee_when_broke() -> void:
	jobs.wallet.credits = 10
	player.rescued.emit("fall")
	assert_eq(jobs.wallet.credits, 0)


func test_hit_by_a_car() -> void:
	var spawn := SpawnFinder.find_on_foot(world.layout)
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((spawn.cell[axis] + 0.5) * world.config.cell_size[axis])
	world.teleport_focus(absolute)
	var safe := player.global_position + Vector3(1, 0, 0)
	player.fall_guard.update(true, safe, 1.0)
	_carry_one()
	jobs.wallet.credits = 100
	# Stand where a car is right now.
	traffic.update()
	var cell := world.origin.absolute_cell_of(player.global_position)
	var lanes := TrafficLanes.new(world.layout)
	var cars := lanes.cars_near(cell, 200.0, TrafficManager.seconds_of(session.clock))
	assert_gt(cars.size(), 0)
	var car: Dictionary = cars[0]
	player.global_position = world.origin.scene_position_of_cell_center(cell) + (car["position"] as Vector3) - Vector3(0, 0.9, 0)
	traffic.update()
	assert_gt(traffic.car_count(), 0)
	assert_eq(hazards.rescues, 1)
	assert_eq(jobs.carried.size(), 0)
	assert_almost_eq(player.global_position, safe, Vector3.ONE * 0.01)
	assert_string_contains(hazards.last_message, "car")
