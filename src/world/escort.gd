class_name Escort
extends Node3D
## A person travelling with the courier (spec escorts): appears when an escort job is carried,
## follows the courier over the navigation graph at walking pace, stops while a gang chases, and
## must be close by at the door for the delivery to count.

const REPLAN_SECONDS := 0.5
const KEEP_DISTANCE := 2.0
const BUDGET := 4000

@export var world_path: NodePath
@export var player_path: NodePath
@export var jobs_path: NodePath
@export var encounters_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var figure: PersonAgent
var job: DeliveryJob
var frightened: bool = false
var path := PackedVector3Array()
var _path_cell := Vector3i.ZERO
var _cell := Vector3i.ZERO
var _local := Vector3.ZERO
var _replan: float = 0.0
var _nav: CityNav


func _process(delta: float) -> void:
	if auto_update:
		update(delta)


func update(delta: float) -> void:
	var world := get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null
	var player := get_node_or_null(player_path) as Player if not player_path.is_empty() else null
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	if world == null or player == null or jobs == null:
		return
	var current := _escort_job(jobs)
	if current == null:
		if figure != null:
			figure.queue_free()
			figure = null
		job = null
		return
	if current != job or figure == null:
		job = current
		_spawn(world, player)
	var encounters := get_node_or_null(encounters_path) as EncounterDirector if not encounters_path.is_empty() else null
	frightened = encounters != null and encounters.state == EncounterDirector.State.CHASE
	if not frightened:
		_follow(world, player, delta)
	figure.global_position = world.origin.scene_position_of_cell_center(_cell) + _local
	figure.animate(delta)


## Whether the escort stands within reach of a scene position (the door).
func is_with(scene_position: Vector3) -> bool:
	return figure != null and figure.global_position.distance_to(scene_position) <= Economy.num("escorts", "with_you")


func _escort_job(jobs: JobManager) -> DeliveryJob:
	for j in jobs.carried:
		if j.cargo_kind == "person":
			return j
	return null


func _spawn(world: CityWorld, player: Player) -> void:
	if figure == null:
		figure = PersonAgent.new()
		figure.set_activity("out")
		add_child(figure)
	figure.label = job.cargo
	_cell = world.origin.absolute_cell_of(player.global_position)
	_local = player.global_position - world.origin.scene_position_of_cell_center(_cell) - player.global_basis.z * -1.5
	path.clear()


func _follow(world: CityWorld, player: Player, delta: float) -> void:
	var base := world.origin.scene_position_of_cell_center(_cell)
	var position := base + _local
	var feet := player.global_position
	_replan -= delta
	if _replan <= 0.0:
		_replan = REPLAN_SECONDS
		_plan(world, position, feet)
	var budget := Economy.num("escorts", "speed") * delta
	while budget > 0.0:
		var aim := feet
		if not path.is_empty():
			aim = world.origin.scene_position_of_cell_center(_path_cell) + path[0]
		elif position.distance_to(feet) <= KEEP_DISTANCE:
			break
		var to_aim := aim - position
		var gap := to_aim.length()
		if path.is_empty():
			gap = maxf(0.0, gap - KEEP_DISTANCE)
		if gap <= budget:
			position += to_aim.normalized() * gap
			budget -= gap
			if path.is_empty():
				break
			path.remove_at(0)
		else:
			position += to_aim.normalized() * budget
			budget = 0.0
	_cell = world.origin.absolute_cell_of(position)
	_local = position - world.origin.scene_position_of_cell_center(_cell)


func _plan(world: CityWorld, from: Vector3, to: Vector3) -> void:
	if _nav == null or _nav.population != world.population:
		_nav = CityNav.new(world.population)
	var from_cell := world.origin.absolute_cell_of(from)
	var to_cell := world.origin.absolute_cell_of(to)
	var start := _nav.nearest_node(from_cell, from - world.origin.scene_position_of_cell_center(from_cell))
	var goal := _nav.nearest_node(to_cell, to - world.origin.scene_position_of_cell_center(to_cell))
	path = PackedVector3Array()
	if start == goal or start.w < 0 or goal.w < 0:
		return
	var route := _nav.route_between(start, goal, 1, BUDGET)
	if not route.is_empty():
		path = route.points.slice(1)
		_path_cell = route.start_cell
