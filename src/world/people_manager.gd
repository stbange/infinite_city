class_name PeopleManager
extends Node3D
## Figures for the people around the player (spec people-in-the-city), placed by their routines:
## inside their workplace, venue or flat, or on their route when walking.

const MAX_AGENTS := 40
const VIEW_DISTANCE := 60.0
const FLOOR_RANGE := 2
## Walking pace in metres per real second.
const WALK_SPEED := 1.3
const CANDIDATES_PER_FRAME := 150
const ROUTES_PER_FRAME := 2
const ROUTE_BUDGET := 8000
const REACH := 3.0

@export var world_path: NodePath
@export var session_path: NodePath
@export var player_path: NodePath
@export var interaction_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var routines: Routines
var nav: CityNav
var _population: Population
var _ids: Array[PersonId] = []
var _cursor: int = 0
var _set_key: String = ""
var _retry_at: int = 0
var _state: Dictionary = {}    # person key -> {"step", "route", "cell", "local", "label"}
var _route_queue: Array[String] = []
var _agents: Dictionary = {}   # person key -> PersonAgent
var _connected: bool = false
## What the last person you spoke to said (spec doorsteps / Figures), for the HUD.
var last_message: String = ""


func _process(_delta: float) -> void:
	if auto_update:
		update()


func agents() -> Array[PersonAgent]:
	var result: Array[PersonAgent] = []
	for agent: PersonAgent in _agents.values():
		result.append(agent)
	return result


func agent_for(key: String) -> PersonAgent:
	return _agents.get(key) as PersonAgent


func candidate_count() -> int:
	return _ids.size()


## The cached routine step of a candidate, or null.
func step_of(key: String) -> RoutineStep:
	var state: Dictionary = _state.get(key, {})
	return state.get("step") as RoutineStep


func route_of(key: String) -> NavRoute:
	var state: Dictionary = _state.get(key, {})
	return state.get("route") as NavRoute


func update() -> void:
	var world := _world()
	var clock := _clock()
	var player := _player()
	if world == null or world.population == null or clock == null or player == null:
		return
	_setup(world)
	var now := clock.exact_minutes()
	_refresh_candidates(world, player)
	_evaluate(int(now), world)
	_find_routes()
	_place(world, player, now, clock.speed)


func _setup(world: CityWorld) -> void:
	if _population != world.population:
		_population = world.population
		routines = Routines.new(_population)
		nav = CityNav.new(_population)
		_state.clear()
		_set_key = ""
	if not _connected:
		var interaction := get_node_or_null(interaction_path) as Interaction if not interaction_path.is_empty() else null
		if interaction != null:
			interaction.add_provider(targets_near)
			interaction.interacted.connect(_on_interacted)
		_connected = true


# --- Candidates ----------------------------------------------------------------------------

func _refresh_candidates(world: CityWorld, player: Player) -> void:
	var cell := world.origin.absolute_cell_of(player.global_position)
	var local_y := player.global_position.y - world.origin.scene_position_of_cell_center(cell).y
	var key := "%s|%d" % [cell, floori(local_y / InteriorLayout.FLOOR_HEIGHT)]
	if key == _set_key and (_retry_at == 0 or Time.get_ticks_msec() < _retry_at):
		return
	_set_key = key
	_retry_at = 0
	var layout := world.layout
	var ids: Array[PersonId] = []
	var missing_market := false
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var block := layout.block_at(cell + Vector3i(dx, 0, dz))
			if block == null:
				continue
			var plan := _population.plan_of(block)
			var f := plan.floor_at(local_y)
			var lo := maxi(0, f - FLOOR_RANGE)
			var hi := mini(plan.floors - 1, f + FLOOR_RANGE)
			if block.kind == BlockTypes.Kind.HOUSING:
				var people := _population.block_people(block)
				for i in people.size():
					if people.floors[i] >= lo and people.floors[i] <= hi:
						ids.append(people.ids[i])
			else:
				var district := layout.district_of(block.cell)
				if not _population.has_job_market(district):
					missing_market = true
					continue
				var market := _population.job_market(district)
				for floor_index in range(lo, hi + 1):
					for unit in plan.units:
						var w := market.workplace_at(PersonId.of(layout, block.cell, floor_index, unit.index, 0))
						if w != null:
							ids.append_array(market.staff_of(w))
	if missing_market:
		_retry_at = Time.get_ticks_msec() + 1000
	var keep := {}
	for id in ids:
		keep[id.key()] = true
	for k: String in _state.keys():
		if not keep.has(k):
			_state.erase(k)
	_ids = ids
	_cursor = 0


func _evaluate(now: int, world: CityWorld) -> void:
	if _ids.is_empty():
		return
	for i in mini(CANDIDATES_PER_FRAME, _ids.size()):
		var id := _ids[_cursor % _ids.size()]
		_cursor += 1
		# Routines need the district's job market; never build it on the main thread.
		if not _population.has_job_market(id.district):
			world.prefetch_job_market(id.district)
			continue
		var key := id.key()
		var state: Dictionary = _state.get(key, {})
		var step := state.get("step") as RoutineStep
		if step != null and step.contains(now):
			continue
		step = routines.at(id, now)
		state = {"step": step, "id": id}
		if step.walking:
			_route_queue.append(key)
		else:
			_station(state, id, step)
		_state[key] = state


## Where a person stands inside the unit of a stationary step (nothing while asleep).
func _station(state: Dictionary, id: PersonId, step: RoutineStep) -> void:
	if step.activity == "sleeping":
		return
	var place := step.place
	var block_nav := nav.block_nav(place.cell)
	if block_nav == null:
		return
	var unit := block_nav.plan.units[place.unit]
	var h := DetHash.hash2(_population.world_seed(), Routines.SALT_ROUTINE + 2, id.local, id.district.y)
	var depth := minf(unit.depth() - 0.8, 1.2 + float(h % 100) / 100.0 * 3.0)
	var half := maxf(0.0, unit.rect.size.x * 0.5 - 0.8)
	var x := clampf(unit.door_x + (float((h >> 8) % 200) / 100.0 - 1.0) * 2.0, unit.rect.get_center().x - half, unit.rect.get_center().x + half)
	state["cell"] = place.cell
	state["local"] = Vector3(x, block_nav.plan.floor_y(place.floor_index), unit.front_z() - unit.front_sign * depth)


func _find_routes() -> void:
	var done := 0
	while done < ROUTES_PER_FRAME and not _route_queue.is_empty():
		var key: String = _route_queue.pop_front()
		var state: Dictionary = _state.get(key, {})
		var step := state.get("step") as RoutineStep
		if step == null or not step.walking or state.has("route"):
			continue
		var route := nav.route(step.from, step.place, CityNav.MAX_CELLS, ROUTE_BUDGET)
		if route.is_empty():
			route = _route_out(step.from)
		state["route"] = route
		done += 1


## A walk out of the block when the whole way is too far to search: to its first entrance.
func _route_out(from: NavPlace) -> NavRoute:
	var block_nav := nav.block_nav(from.cell)
	if block_nav == null or block_nav.plan.entrances.is_empty():
		return NavRoute.new()
	var entrance := block_nav.plan.entrances[0]
	return nav.route(from, NavPlace.entrance(from.cell, entrance.floor_index, entrance.face_axis, entrance.face_sign), 0, ROUTE_BUDGET)


# --- Placement -----------------------------------------------------------------------------

func _place(world: CityWorld, player: Player, now: float, speed: float) -> void:
	var feet := player.global_position
	var shown: Array = []   # [distance, key, position, direction]
	for key: String in _state:
		var state: Dictionary = _state[key]
		var step := state.get("step") as RoutineStep
		if step == null:
			continue
		var position := Vector3.ZERO
		var direction := Vector3.ZERO
		if step.walking:
			var route := state.get("route") as NavRoute
			if route == null or route.is_empty():
				continue
			var walked := maxf(0.0, now - step.start) / maxf(speed, 0.0001) * WALK_SPEED
			if walked > route.length + 0.01 and not route.nodes.is_empty() and _left_block(route, step):
				continue
			var base := world.origin.scene_position_of_cell_center(route.start_cell)
			position = base + route.point_at(walked)
			direction = route.direction_at(walked)
		elif state.has("local"):
			position = world.origin.scene_position_of_cell_center(state["cell"]) + (state["local"] as Vector3)
		else:
			continue
		var distance := position.distance_to(feet)
		if distance <= VIEW_DISTANCE:
			shown.append([distance, key, position, direction])
	shown.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var visible := {}
	for i in mini(MAX_AGENTS, shown.size()):
		var entry: Array = shown[i]
		var key: String = entry[1]
		visible[key] = true
		var agent := _agents.get(key) as PersonAgent
		if agent == null:
			agent = PersonAgent.new()
			agent.person_key = key
			add_child(agent)
			_agents[key] = agent
		var state: Dictionary = _state[key]
		var step := state["step"] as RoutineStep
		agent.set_activity("walking" if step.walking else step.activity)
		if not state.has("label"):
			state["label"] = _label(state["id"], step)
		agent.label = state["label"]
		agent.global_position = entry[2]
		agent.animate(get_process_delta_time() if is_inside_tree() else 0.016)
		var direction: Vector3 = entry[3]
		direction.y = 0.0
		if direction.length_squared() > 0.01:
			agent.global_basis = Basis.looking_at(direction.normalized(), Vector3.UP)
	for key: String in _agents.keys():
		if not visible.has(key):
			(_agents[key] as PersonAgent).queue_free()
			_agents.erase(key)


## True when a finished partial walk ended at an entrance (the person has gone on into the city).
func _left_block(route: NavRoute, step: RoutineStep) -> bool:
	var last := route.nodes[route.nodes.size() - 1]
	return Vector3i(last.x, last.y, last.z) != step.place.cell or nav.node_of(step.place).w != last.w


func _label(id: PersonId, step: RoutineStep) -> String:
	var person := _population.person(id)
	if person == null:
		return step.activity
	return "%s %s, %d · %s" % [person.given_name, person.family_name, person.age, step.activity]


## Pressing E on a figure: they share a piece of gossip.
func _on_interacted(target: Dictionary) -> void:
	if target.get("kind") != "person":
		return
	var world := _world()
	var key := str((target.get("payload", {}) as Dictionary).get("person", ""))
	if world == null or world.gossip == null or key.is_empty():
		return
	var id := PersonId.from_key(key)
	var person := _population.person(id)
	var heard := world.gossip.about(id) if _population.has_job_market(id.district) else PackedStringArray()
	var who := person.given_name if person != null else "They"
	last_message = "%s: \"%s\"" % [who, heard[0] if not heard.is_empty() else "Busy night, courier."]


## Interaction targets: figures within reach of a point (spec people-in-the-city / Looking at a person).
func targets_near(near: Vector3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for agent: PersonAgent in _agents.values():
		var head := agent.global_position + Vector3(0, 1.5, 0)
		if head.distance_to(near) <= REACH:
			result.append({"position": head, "label": agent.label, "kind": "person", "payload": {"person": agent.person_key}})
	return result


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _clock() -> GameClock:
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	return session.clock if session != null else null


func _player() -> Player:
	return get_node_or_null(player_path) as Player if not player_path.is_empty() else null
