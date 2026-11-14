class_name StoryRunner
extends Node
## Runs the plot (spec story-director / Story runner): casts it once the courier's patron is known,
## starts beats on deliveries, hands out story jobs, opens scenes and applies choices.

const STORY_PAY := 15
## How close the courier must come to a figure to meet them (spec doorsteps / Meetings).
const MEET_DISTANCE := 3.5

@export var world_path: NodePath
@export var session_path: NodePath
@export var jobs_path: NodePath
@export var panel_path: NodePath
@export var encounters_path: NodePath
@export var simulation_path: NodePath
@export var menu_path: NodePath
@export var people_path: NodePath
@export var player_path: NodePath
@export var interaction_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var plot: Dictionary = StoryDirector.template()
var state := StoryState.new()
var _cast_key: Array = []
var _connected: bool = false
var _routines: Routines


func _process(_delta: float) -> void:
	if auto_update:
		update()


func update() -> void:
	var world := _world()
	var jobs := _jobs()
	if world == null or world.population == null or jobs == null or jobs.patron == null:
		return
	_connect()
	if not state.is_cast():
		_poll_cast(world, jobs.patron)
		return
	if state.active.is_empty():
		StoryDirector.begin(plot, state, jobs.completed)
	if not state.job_role.is_empty():
		_ensure_story_job(world, jobs)
	if not state.meet_role.is_empty() and _figure_in_reach():
		StoryDirector.met(plot, state)
	var panel := _panel()
	if not state.scene.is_empty() and panel != null and not panel.is_open():
		var menu := get_node_or_null(menu_path) as GameMenu if not menu_path.is_empty() else null
		var courier: Dictionary = menu.profile if menu != null else {}
		panel.open(StoryDirector.scene_text(plot, state, world.config.world_seed, courier),
				StoryDirector.choice_texts(plot, state, world.config.world_seed, courier))


## Casts right now on this thread (tests, or when no background jobs are available).
func cast_now(world: CityWorld, patron: WorkplaceInfo) -> void:
	state.template_id = plot["id"]
	state.cast = StoryDirector.cast(world.population, world.chronicle, patron.cell, patron, plot)


func _poll_cast(world: CityWorld, patron: WorkplaceInfo) -> void:
	if _cast_key.is_empty():
		_cast_key = ["story-cast", patron.cell, patron.floor_index, patron.unit]
		var config := world.config
		var where := [patron.cell, patron.floor_index, patron.unit]
		world.background.submit(_cast_key, func() -> Variant:
			var layout := CityLayout.new(config)
			var population := Population.new(layout, null)
			var chronicle := CityChronicle.new(config)
			var w := population.workplace(where[0], where[1], where[2])
			var id := StoryDirector.pick_template(chronicle, layout, where[0])
			return {"template": id, "cast": StoryDirector.cast(population, chronicle, where[0], w, StoryDirector.template(id))})
	if world.background.is_ready(_cast_key):
		var found: Dictionary = world.background.result(_cast_key)
		plot = StoryDirector.template(found["template"])
		state.template_id = found["template"]
		state.cast = found["cast"]


func _ensure_story_job(world: CityWorld, jobs: JobManager) -> void:
	for job in jobs.carried:
		if job.story_beat == state.active:
			return
	var entry: Dictionary = state.cast.get(state.job_role, {})
	if entry.is_empty():
		return
	var spec: Dictionary = StoryDirector.beat(plot, state.active)["job"]
	var job := DeliveryJob.new()
	job.id = "story:" + state.active
	job.story_beat = state.active
	job.pickup = jobs.patron.id
	job.patron_name = jobs.patron.name
	var cell: Array = entry["cell"]
	job.dropoff_cell = Vector3i(int(cell[0]), int(cell[1]), int(cell[2]))
	job.dropoff_floor = int(entry["floor"])
	job.dropoff_unit = int(entry["unit"])
	job.customer = PersonId.from_key(entry["key"])
	job.customer_name = ("%s %s" % [entry["first"], entry["family"]]).strip_edges()
	job.cargo = str(spec.get("cargo", "parcel"))
	job.cargo_kind = str(spec.get("kind", "food"))
	job.base_pay = STORY_PAY
	var session := _session()
	job.picked_minute = session.clock.total_minutes if session != null else 0
	jobs.carried.insert(0, job)


## Where the person to meet is now: the unit their routine puts them in, else their home.
func meet_place() -> Dictionary:
	var entry: Dictionary = state.cast.get(state.meet_role, {})
	if not entry.has("cell"):
		return {}
	var c: Array = entry["cell"]
	var place := {"cell": Vector3i(int(c[0]), int(c[1]), int(c[2])), "floor": int(entry["floor"]), "unit": int(entry["unit"])}
	var world := _world()
	var session := _session()
	var id := PersonId.from_key(entry["key"])
	if world != null and session != null and world.population.has_job_market(id.district):
		if _routines == null or _routines.population != world.population:
			_routines = Routines.new(world.population)
		var step := _routines.at(id, session.clock.total_minutes)
		var at := step.place
		if not step.walking and at.where == NavPlace.Where.UNIT:
			place = {"cell": at.cell, "floor": at.floor_index, "unit": at.unit}
	return place


func _figure_in_reach() -> bool:
	var people := get_node_or_null(people_path) as PeopleManager if not people_path.is_empty() else null
	var player := get_node_or_null(player_path) as Player if not player_path.is_empty() else null
	var entry: Dictionary = state.cast.get(state.meet_role, {})
	if people == null or player == null or not entry.has("key"):
		return false
	var agent := people.agent_for(entry["key"])
	return agent != null and agent.global_position.distance_to(player.global_position) <= MEET_DISTANCE


func _on_interacted(target: Dictionary) -> void:
	if state.meet_role.is_empty():
		return
	var payload: Dictionary = target.get("payload", {})
	var entry: Dictionary = state.cast.get(state.meet_role, {})
	var found := false
	if target.get("kind") == "person":
		found = payload.get("person") == entry.get("key")
	elif target.get("kind") == "door":
		var place := meet_place()
		found = not place.is_empty() and payload.get("cell") == place["cell"] and payload.get("floor") == place["floor"] \
				and payload.get("unit") == place["unit"]
	if found:
		StoryDirector.met(plot, state)


func _connect() -> void:
	if _connected:
		return
	var interaction := get_node_or_null(interaction_path) as Interaction if not interaction_path.is_empty() else null
	if interaction != null:
		interaction.interacted.connect(_on_interacted)
	_jobs().delivered.connect(_on_delivered)
	var panel := _panel()
	if panel != null:
		panel.chosen.connect(choose)
	var session := _session()
	if session != null:
		session.register_part("story", to_dict, from_dict)
	_connected = true


func _on_delivered(job: DeliveryJob) -> void:
	if not job.story_beat.is_empty() and job.story_beat == state.active:
		StoryDirector.deliver_story_job(plot, state)


## Picks a choice of the open scene.
func choose(index: int) -> void:
	var jobs := _jobs()
	var effects := StoryDirector.choose(plot, state, index, jobs.completed if jobs != null else 0)
	var encounters := get_node_or_null(encounters_path) as EncounterDirector if not encounters_path.is_empty() else null
	var session := _session()
	var heat: Dictionary = effects["heat"]
	if encounters != null and session != null:
		for gang: String in heat:
			encounters.heat.add(gang, heat[gang], session.clock.total_minutes)
	if jobs != null:
		jobs.courier.wallet.credits += int(effects["wallet"])
	var simulation := get_node_or_null(simulation_path) as SimulationRunner if not simulation_path.is_empty() else null
	if simulation != null and session != null:
		for key: String in effects["kill"]:
			simulation.record({"kind": "death", "person": key}, session.clock.total_minutes)
		for effect: String in effects["world"]:
			simulation.story_effect(effect, state.cast, session.clock.total_minutes)
	if jobs != null:
		StoryDirector.begin(plot, state, jobs.completed)


func objective_text() -> String:
	if not state.is_cast():
		return ""
	var text := StoryDirector.objective(plot, state)
	var jobs := _jobs()
	var place := meet_place() if not state.meet_role.is_empty() else {}
	if not place.is_empty() and jobs != null and jobs.names != null:
		text += " · now at %s" % Address.format(jobs.names, place["cell"], place["floor"], place["unit"])
	return text


func to_dict() -> Dictionary:
	return state.to_dict()


func from_dict(data: Dictionary) -> void:
	state.from_dict(data)
	if not state.template_id.is_empty():
		plot = StoryDirector.template(state.template_id)


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _session() -> GameSession:
	return get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null


func _jobs() -> JobManager:
	return get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null


func _panel() -> DialoguePanel:
	return get_node_or_null(panel_path) as DialoguePanel if not panel_path.is_empty() else null
