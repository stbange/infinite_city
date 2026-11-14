class_name JobManager
extends Node
## The courier loop (spec courier-jobs): the patron's counter offers food orders, interacting with
## the patron's door accepts one, interacting with the customer's door delivers it; pay, rent and
## the waypoint to the next door.

const MAX_CARRIED := 3

## Emitted after a delivery has been paid.
signal delivered(job: DeliveryJob)

@export var world_path: NodePath
@export var session_path: NodePath
@export var interaction_path: NodePath
## Optional: who answers the door decides the tip (spec doorsteps).
@export var doorstep_path: NodePath
## Optional: an escort job only counts with the escort at the door (spec escorts).
@export var escort_path: NodePath

## Wallet, standing, licence and tools (spec courier-state).
var courier := CourierState.new()
## The changed world (spec live-simulation): prices and the dead; null for the baseline.
var overlays: WorldOverlays
var carried: Array[DeliveryJob] = []
var completed: int = 0
## Orders rival couriers took from the counter this hour (spec rival-couriers).
var rivals_this_hour: int = 0
## Why the last door interaction did nothing, for the HUD.
var last_message: String = ""
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
			courier.wallet.start(session.clock)
			_wallet_started = true
		courier.wallet.update(session.clock)
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
			session.register_part("courier_state", courier.to_dict, _load_state)


func set_patron(workplace: WorkplaceInfo) -> void:
	_ensure_setup()
	patron = workplace


## Finds the start scenario around a cell on a worker thread.
func start_at(cell: Vector3i) -> void:
	_ensure_setup()
	_start_cell = cell
	_start_pending = true
	CourierStart.submit(_world(), cell)


func _poll_start() -> void:
	var found: Variant = CourierStart.poll(_world(), _start_cell)
	if found == null:
		return
	_start_pending = false
	if (found as Dictionary).is_empty():
		return
	if patron == null:
		patron = found["patron"]
	home = found["home"]


## Open orders at the patron's counter this hour.
func open_orders() -> Array[DeliveryJob]:
	var result: Array[DeliveryJob] = []
	var session := _session()
	if patron == null or board == null or session == null:
		return result
	var offers := board.offers(patron, session.clock.day_number(), session.clock.hour(), Licence.max_tier(courier.licence))
	var rivals := 0
	for i in offers.size():
		var job := offers[i]
		if _taken.has(job.id):
			continue
		var rival := board.rival_minute(patron, session.clock.day_number(), session.clock.hour(), i)
		if rival >= 0 and session.clock.minute() >= rival:
			rivals += 1
			continue
		if overlays != null:
			if overlays.is_dead(job.customer.key()) or overlays.has_moved(job.customer.key()):
				continue
			job.base_pay = roundi(job.base_pay * overlays.price_factor(_world().layout.district_of(job.dropoff_cell)))
		result.append(job)
	rivals_this_hour = rivals
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
	var done := _job_at(payload)
	var escort := get_node_or_null(escort_path) as Escort if not escort_path.is_empty() else null
	if done != null and done.cargo_kind == "person" and escort != null \
			and not escort.is_with(DoorPlaces.scene_position(_world(), done.dropoff_cell, done.dropoff_floor, done.dropoff_unit)):
		last_message = "Your passenger is not with you"
		return
	if done != null:
		var doorstep := get_node_or_null(doorstep_path) as Doorstep if not doorstep_path.is_empty() else null
		var tip := float(doorstep.answer(done)["tip"]) if doorstep != null else 1.0
		done.paid = CourierBoard.pay_for(done, session.clock.total_minutes, tip)
		courier.wallet.credits += done.paid
		carried.erase(done)
		completed += 1
		courier.reputation.add(Reputation.MUTUAL, Reputation.DELIVERY if done.story_beat.is_empty() else Reputation.STORY_DELIVERY)
		delivered.emit(done)


## Drops all carried orders (taken by a gang or lost in a fall); returns how many were lost.
func lose_cargo() -> int:
	var lost := carried.size()
	carried.clear()
	return lost


## The next door to go to (see CourierWaypoint).
func waypoint() -> Dictionary:
	return CourierWaypoint.of(self, _world())


func to_dict() -> Dictionary:
	var jobs_data: Array = []
	for job in carried:
		jobs_data.append(job.to_dict())
	return {"carried": jobs_data, "completed": completed}


func from_dict(data: Dictionary) -> void:
	if data.has("wallet"):
		_load_state(data)   # version 2 kept the courier's state in this part
	carried.clear()
	for item: Dictionary in data.get("carried", []):
		carried.append(DeliveryJob.from_dict(item))
		_taken[carried[-1].id] = true
	completed = int(data.get("completed", 0))


func _load_state(data: Dictionary) -> void:
	courier.from_dict(data)
	_wallet_started = true


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _session() -> GameSession:
	return get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
