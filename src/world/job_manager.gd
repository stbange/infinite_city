class_name JobManager
extends Node
## The courier loop (spec courier-jobs): the patron's counter offers food orders, interacting with
## the patron's door accepts one, interacting with the customer's door delivers it; pay, rent and
## the waypoint to the next door.

const MAX_CARRIED := 3

@export var world_path: NodePath
@export var session_path: NodePath
@export var interaction_path: NodePath

var wallet := Wallet.new()
var carried: Array[DeliveryJob] = []
var completed: int = 0
var patron: WorkplaceInfo
var home := {}
var board: CourierBoard
var names: PlaceNames

var _taken: Dictionary = {}   # job ids accepted this hour
var _connected: bool = false
var _wallet_started: bool = false
var _start_cell := Vector3i.ZERO
var _start_pending: bool = false


func _process(_delta: float) -> void:
	_ensure_setup()
	var session := _session()
	if session != null:
		if not _wallet_started:
			wallet.start(session.clock)
			_wallet_started = true
		wallet.update(session.clock)
	if _start_pending:
		_poll_start()


func _ensure_setup() -> void:
	var world := _world()
	if world == null or world.population == null:
		return
	if board == null:
		board = CourierBoard.new(world.population)
		names = PlaceNames.new(world.layout)
	if not _connected:
		var interaction := get_node_or_null(interaction_path) as Interaction if not interaction_path.is_empty() else null
		if interaction != null:
			interaction.interacted.connect(_on_interacted)
			interaction.add_label_hook(_label_for)
			_connected = true
		var session := _session()
		if session != null:
			session.register_part("courier", to_dict, from_dict)


func set_patron(workplace: WorkplaceInfo) -> void:
	_ensure_setup()
	patron = workplace


## Finds the start scenario around a cell on a worker thread (its own layout and population).
func start_at(cell: Vector3i) -> void:
	_ensure_setup()
	var world := _world()
	_start_cell = cell
	_start_pending = true
	var config := world.config
	world.background.submit(["start", cell], func() -> Variant:
		var population := Population.new(CityLayout.new(config), null)
		var found := StartScenario.find(population, cell)
		if found.is_empty():
			return {}
		var w: WorkplaceInfo = found["patron"]
		return {"patron": [w.cell, w.floor_index, w.unit], "home": [found["home_cell"], found["home_floor"], found["home_unit"]]})


func _poll_start() -> void:
	var world := _world()
	var key := ["start", _start_cell]
	world.background.poll()
	if not world.background.is_ready(key):
		return
	_start_pending = false
	var found: Dictionary = world.background.result(key)
	if found.is_empty():
		return
	var p: Array = found["patron"]
	var market := world.population.job_market(world.layout.district_of(p[0]))
	var w := market.workplace_at(PersonId.of(world.layout, p[0], p[1], p[2], 0))
	if patron == null:
		patron = w
	var h: Array = found["home"]
	home = {"cell": h[0], "floor": h[1], "unit": h[2]}


## Open orders at the patron's counter this hour.
func open_orders() -> Array[DeliveryJob]:
	var result: Array[DeliveryJob] = []
	var session := _session()
	if patron == null or board == null or session == null:
		return result
	for job in board.offers(patron, session.clock.day_number(), session.clock.hour()):
		if not _taken.has(job.id):
			result.append(job)
	return result


func _is_patron_door(payload: Dictionary) -> bool:
	return patron != null and payload.get("cell") == patron.cell and payload.get("floor") == patron.floor_index \
			and payload.get("unit") == patron.unit


func _job_at(payload: Dictionary) -> DeliveryJob:
	for job in carried:
		if payload.get("cell") == job.dropoff_cell and payload.get("floor") == job.dropoff_floor \
				and payload.get("unit") == job.dropoff_unit:
			return job
	return null


func _label_for(target: Dictionary) -> String:
	if target.get("kind") != "door":
		return ""
	var payload: Dictionary = target.get("payload", {})
	if _is_patron_door(payload):
		return "Jobs at %s" % patron.name
	var job := _job_at(payload)
	if job != null:
		return "Deliver to %s" % job.customer_name
	return ""


func _on_interacted(target: Dictionary) -> void:
	if target.get("kind") != "door":
		return
	var payload: Dictionary = target.get("payload", {})
	var session := _session()
	if _is_patron_door(payload):
		if carried.size() >= MAX_CARRIED:
			return
		var orders := open_orders()
		if orders.is_empty():
			return
		var job := orders[0]
		job.picked_minute = session.clock.total_minutes
		_taken[job.id] = true
		carried.append(job)
		return
	var delivered := _job_at(payload)
	if delivered != null:
		wallet.credits += CourierBoard.pay_for(delivered, session.clock.total_minutes)
		carried.erase(delivered)
		completed += 1


## Scene position of a unit's door, 1.1 m above its floor.
func door_position(cell: Vector3i, floor_index: int, unit_index: int) -> Vector3:
	var world := _world()
	var block := world.layout.block_at(cell)
	var plan := world.population.plan_of(block)
	var unit := plan.units[unit_index]
	return world.origin.scene_position_of_cell_center(cell) + Vector3(unit.door_x, plan.floor_y(floor_index) + 1.1, unit.front_z())


## {position, label, floor} of the next door to go to: the first carried order's drop-off, or
## the patron's counter.
func waypoint() -> Dictionary:
	if not carried.is_empty():
		var job := carried[0]
		return {"position": door_position(job.dropoff_cell, job.dropoff_floor, job.dropoff_unit),
			"label": "%s: %s" % [job.customer_name, job.cargo], "floor": job.dropoff_floor,
			"address": Address.format(names, job.dropoff_cell, job.dropoff_floor, job.dropoff_unit)}
	if patron != null:
		return {"position": door_position(patron.cell, patron.floor_index, patron.unit),
			"label": "Jobs at %s" % patron.name, "floor": patron.floor_index,
			"address": Address.format(names, patron.cell, patron.floor_index, patron.unit)}
	return {}


func to_dict() -> Dictionary:
	var jobs_data: Array = []
	for job in carried:
		jobs_data.append(job.to_dict())
	return {"wallet": wallet.to_dict(), "carried": jobs_data, "completed": completed}


func from_dict(data: Dictionary) -> void:
	wallet.from_dict(data.get("wallet", {}))
	_wallet_started = true
	carried.clear()
	for item: Dictionary in data.get("carried", []):
		carried.append(DeliveryJob.from_dict(item))
		_taken[carried[-1].id] = true
	completed = int(data.get("completed", 0))


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _session() -> GameSession:
	return get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
