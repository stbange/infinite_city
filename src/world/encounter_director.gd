class_name EncounterDirector
extends Node3D
## Gangs on their bridges (specs gang-turf, encounters): a courier with cargo on a claimed bridge
## is stopped once per bridge and game hour; pay, talk or run; a chase ends in escape or capture.

## Emitted with the amount when the courier pays a gang.
signal paid(amount: int)

enum State { IDLE, OFFER, CHASE }

const FIGURES := 3
const FRIENDLY_DISCOUNT := 0.7
const DECK_MARGIN := 0.6

@export var world_path: NodePath
@export var session_path: NodePath
@export var player_path: NodePath
@export var jobs_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var turf: TurfMap
var heat := Heat.new()
var state: int = State.IDLE
var kind: String = ""
var gang_key: String = ""
var price: int = 0
var talked: bool = false
var chase_time: float = 0.0
## Message about the last outcome, for the HUD.
var last_outcome: String = ""
var bridge: BridgeInfo
var _resolved: Dictionary = {}   # "cell|axis|hour" -> true
var _figures: Array[PersonAgent] = []
var _figure_cells: Array[Vector3i] = []
var _figure_locals: Array[Vector3] = []
var _registered: bool = false


func _process(delta: float) -> void:
	if auto_update:
		update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if state != State.OFFER or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_1:
			pay()
		KEY_2:
			talk()
		KEY_3:
			run()


func update(delta: float) -> void:
	var world := _world()
	var session := _session()
	var player := _player()
	if world == null or world.chronicle == null or session == null or player == null:
		return
	if turf == null:
		turf = TurfMap.new(world.chronicle, world.layout)
	if not _registered:
		session.register_part("encounters", to_dict, from_dict)
		_registered = true
	match state:
		State.IDLE:
			_check_bridge(world, session, player)
		State.OFFER:
			if bridge_under(world, player.global_position) == null:
				run()
		State.CHASE:
			_chase(world, player, delta)
	_place_figures(world)


## The bridge whose deck is under a scene position (feet), or null.
func bridge_under(world: CityWorld, feet: Vector3) -> BridgeInfo:
	var cell := world.origin.absolute_cell_of(feet)
	for candidate_cell: Vector3i in [cell, cell - Vector3i(1, 0, 0), cell - Vector3i(0, 0, 1)]:
		for axis in CityLayout.BRIDGE_AXES:
			var b := world.layout.bridge_between(candidate_cell, axis)
			if b == null:
				continue
			var local := feet - world.origin.scene_position_of_cell_center(b.cell_a)
			var lateral := 2 if axis == Vector3.AXIS_X else 0
			if local[axis] < b.start[axis] - DECK_MARGIN or local[axis] > b.end[axis] + DECK_MARGIN:
				continue
			if absf(local[lateral] - b.start[lateral]) > b.width * 0.5 + DECK_MARGIN:
				continue
			if absf(local.y - b.start.y) > 2.0:
				continue
			return b
	return null


func _hour(session: GameSession) -> int:
	return session.clock.total_minutes / 60


func _resolved_key(b: BridgeInfo, hour: int) -> String:
	return "%s|%d|%d" % [b.cell_a, b.axis, hour]


func _check_bridge(world: CityWorld, session: GameSession, player: Player) -> void:
	var jobs := _jobs()
	if jobs == null or jobs.carried.is_empty() or player.mode != Player.Mode.WALK:
		return
	var b := bridge_under(world, player.global_position)
	if b == null:
		return
	var claim := turf.claim_of(b)
	var hour := _hour(session)
	if claim.is_empty() or _resolved.has(_resolved_key(b, hour)):
		return
	_resolved[_resolved_key(b, hour)] = true
	var minute := session.clock.total_minutes
	var h := heat.value_at(claim, minute) + CargoKind.total_heat(jobs.carried)
	var standing := jobs.courier.reputation.level(claim)
	var outcome := EncounterRules.roll(world.config.world_seed, b, hour, jobs.carried.size(), h)
	if outcome == "pass" or standing == "trusted":
		return
	bridge = b
	gang_key = claim
	kind = outcome
	talked = false
	price = EncounterRules.toll(jobs.carried.size(), h) * (2 if outcome == "shakedown" else 1)
	if standing == "friendly":
		price = roundi(price * FRIENDLY_DISCOUNT)
	state = State.OFFER
	_spawn_figures(world, player)


func gang_name() -> String:
	var gang := turf.gang(gang_key) if turf != null else null
	return gang.name if gang != null else "a gang"


## Pays the asking price (all the courier has if short, with heat for the rest).
func pay() -> void:
	if state != State.OFFER:
		return
	var jobs := _jobs()
	var amount := mini(price, jobs.courier.wallet.credits)
	jobs.courier.wallet.credits -= amount
	if amount < price:
		heat.add(gang_key, EncounterRules.SHORT_HEAT, _session().clock.total_minutes)
	else:
		jobs.courier.reputation.add(gang_key, Reputation.TOLL_PAID)
	last_outcome = "Paid ¤%d to %s" % [amount, gang_name()]
	paid.emit(amount)
	_end()


## Tries to talk the way through once; failing doubles the price.
func talk() -> void:
	if state != State.OFFER or talked:
		return
	talked = true
	var session := _session()
	var h := heat.value_at(gang_key, session.clock.total_minutes)
	if EncounterRules.talk_succeeds(_world().config.world_seed, bridge, _hour(session), h):
		last_outcome = "%s let you pass" % gang_name()
		_end()
	else:
		kind = "shakedown"
		price *= 2
		last_outcome = "%s are not amused: ¤%d now" % [gang_name(), price]


## Refuses and runs: the gang gives chase.
func run() -> void:
	if state != State.OFFER:
		return
	heat.add(gang_key, EncounterRules.RUN_HEAT, _session().clock.total_minutes)
	_jobs().courier.reputation.add(gang_key, Reputation.RAN)
	state = State.CHASE
	chase_time = 0.0
	last_outcome = "Run! %s give chase" % gang_name()


func _chase(world: CityWorld, player: Player, delta: float) -> void:
	chase_time += delta
	var feet := player.global_position
	var nearest := INF
	for i in _figures.size():
		var base := world.origin.scene_position_of_cell_center(_figure_cells[i])
		var position := base + _figure_locals[i]
		var to_player := feet - position
		var step := minf(EncounterRules.GANG_SPEED * delta, to_player.length())
		if to_player.length() > 0.001:
			position += to_player.normalized() * step
		_figure_locals[i] = position - base
		nearest = minf(nearest, position.distance_to(feet))
	if nearest <= EncounterRules.CATCH_DISTANCE:
		var jobs := _jobs()
		var lost := jobs.lose_cargo()
		jobs.courier.reputation.add(gang_key, Reputation.CAUGHT)
		var taken := mini(price, jobs.courier.wallet.credits)
		jobs.courier.wallet.credits -= taken
		last_outcome = "Caught by %s: %d orders and ¤%d gone" % [gang_name(), lost, taken]
		_end()
	elif nearest >= EncounterRules.ESCAPE_DISTANCE or chase_time >= EncounterRules.CHASE_SECONDS:
		last_outcome = "You lost %s in the fog" % gang_name()
		_end()


## Ends a chase as an escape (a flare, spec traversal-tools).
func break_chase(message: String) -> bool:
	if state != State.CHASE:
		return false
	last_outcome = message
	_end()
	return true


## Distance from the player to the nearest chasing figure (INF when not chased).
func chase_distance() -> float:
	var player := _player()
	if state != State.CHASE or player == null or _figures.is_empty():
		return INF
	var nearest := INF
	for f in _figures:
		nearest = minf(nearest, f.global_position.distance_to(player.global_position))
	return nearest


func _end() -> void:
	state = State.IDLE
	for f in _figures:
		f.queue_free()
	_figures.clear()
	_figure_cells.clear()
	_figure_locals.clear()


func _spawn_figures(world: CityWorld, player: Player) -> void:
	var base := world.origin.scene_position_of_cell_center(bridge.cell_a)
	var local := player.global_position - base
	var mid := (bridge.start + bridge.end) * 0.5
	# Block the way ahead: the far half of the deck from where the courier stands.
	var ahead := bridge.end if local.distance_to(bridge.start) < local.distance_to(bridge.end) else bridge.start
	var spot := mid.lerp(ahead, 0.5)
	var lateral := Vector3(0, 0, 1) if bridge.axis == Vector3.AXIS_X else Vector3(1, 0, 0)
	for i in FIGURES:
		var agent := PersonAgent.new()
		agent.set_activity("gang")
		agent.person_key = gang_key
		agent.label = gang_name()
		add_child(agent)
		_figures.append(agent)
		_figure_cells.append(bridge.cell_a)
		_figure_locals.append(spot + lateral * (float(i) - 1.0) * 0.9)


func _place_figures(world: CityWorld) -> void:
	for i in _figures.size():
		_figures[i].global_position = world.origin.scene_position_of_cell_center(_figure_cells[i]) + _figure_locals[i]


func hud_line() -> String:
	match state:
		State.OFFER:
			var what := "toll" if kind == "toll" else "shakedown"
			var talk_text := "" if talked else " · 2 talk"
			return "%s block the bridge: %s ¤%d — 1 pay%s · 3 run" % [gang_name(), what, price, talk_text]
		State.CHASE:
			return "Chased by %s · %d m" % [gang_name(), roundi(chase_distance())]
	return last_outcome


func to_dict() -> Dictionary:
	return {"heat": heat.to_dict()}


func from_dict(data: Dictionary) -> void:
	heat.from_dict(data.get("heat", {}))


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _session() -> GameSession:
	return get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null


func _player() -> Player:
	return get_node_or_null(player_path) as Player if not player_path.is_empty() else null


func _jobs() -> JobManager:
	return get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
