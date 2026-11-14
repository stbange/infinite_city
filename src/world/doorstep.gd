class_name Doorstep
extends Node3D
## The hand-over at the door (spec doorsteps): asks the doorstep rules who answers, shows them in
## the doorway for a few seconds and tells the HUD what they said.

const SHOW_SECONDS := 5.0

@export var world_path: NodePath
@export var session_path: NodePath

var last_message: String = ""
var last_answer: Dictionary = {}
var routines: Routines
var _figure: PersonAgent
var _figure_time: float = 0.0


func _process(delta: float) -> void:
	if _figure_time > 0.0:
		_figure_time -= delta
		if _figure_time <= 0.0 and _figure != null:
			_figure.visible = false


## Who answers the door for a delivery; {state, who, tip, line}.
func answer(job: DeliveryJob) -> Dictionary:
	var world := get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	if world == null or session == null:
		last_answer = {"state": "home", "who": job.customer, "tip": 1.0, "line": ""}
		return last_answer
	if not world.population.has_job_market(job.customer.district):
		# Routines are not known yet: the customer answers.
		last_answer = {"state": "home", "who": job.customer, "tip": 1.0, "line": ""}
		_show_figure(world, job)
		return last_answer
	if routines == null or routines.population != world.population:
		routines = Routines.new(world.population)
	last_answer = DoorstepRules.answer(world.population, routines, job.customer, session.clock.total_minutes)
	last_message = last_answer["line"]
	if last_answer["who"] != null:
		_show_figure(world, job)
	return last_answer


func figure_visible() -> bool:
	return _figure != null and _figure.visible


func _show_figure(world: CityWorld, job: DeliveryJob) -> void:
	if _figure == null:
		_figure = PersonAgent.new()
		add_child(_figure)
	var plan := world.population.plan_of(world.layout.block_at(job.dropoff_cell))
	var unit := plan.units[job.dropoff_unit]
	var local := Vector3(unit.door_x, plan.floor_y(job.dropoff_floor), unit.front_z() - unit.front_sign * 0.6)
	_figure.global_position = world.origin.scene_position_of_cell_center(job.dropoff_cell) + local
	_figure.set_activity("at home")
	_figure.visible = true
	_figure_time = SHOW_SECONDS
