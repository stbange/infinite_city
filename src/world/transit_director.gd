class_name TransitDirector
extends Node
## Transit hubs and lifts in use (spec transit): E at a hub's platform door offers rides to the
## linked hubs for a fare (free with a transit pass); E at the stair core of a tall block offers
## the lift. A ride puts the courier in front of the destination's door or landing.

@export var world_path: NodePath
@export var player_path: NodePath
@export var session_path: NodePath
@export var jobs_path: NodePath
@export var interaction_path: NodePath
@export var interiors_path: NodePath
@export var panel_path: NodePath

var network: TransitNetwork
var names: PlaceNames
var last_message: String = ""
## What the open panel offers: Array of {kind: "hub" | "lift", ...}.
var choices: Array[Dictionary] = []
var _connected: bool = false


func _process(_delta: float) -> void:
	_setup()


func _setup() -> void:
	var world := _world()
	if world == null or world.population == null:
		return
	if network == null or network.population != world.population:
		network = TransitNetwork.new(world.population)
		names = PlaceNames.new(world.layout)
	if _connected:
		return
	var interaction := get_node_or_null(interaction_path) as Interaction if not interaction_path.is_empty() else null
	if interaction != null:
		interaction.interacted.connect(_on_interacted)
		interaction.add_label_hook(_label_for)
		interaction.add_provider(lift_targets)
	var panel := _panel()
	if panel != null:
		panel.chosen.connect(_on_chosen)
	_connected = true


func _is_hub_door(payload: Dictionary) -> bool:
	var world := _world()
	if world == null or not payload.has("cell"):
		return false
	var hub := network.hub_of(world.layout.district_of(payload["cell"]))
	return not hub.is_empty() and hub["cell"] == payload["cell"] and hub["floor"] == payload["floor"] and hub["unit"] == payload["unit"]


func _label_for(target: Dictionary) -> String:
	if target.get("kind") == "door" and network != null and _is_hub_door(target.get("payload", {})):
		return "Transit hub · ride"
	return ""


## Stair-core landings of tall entered blocks near a point, as interaction targets.
func lift_targets(near: Vector3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var interiors := get_node_or_null(interiors_path) as InteriorManager if not interiors_path.is_empty() else null
	if interiors == null:
		return result
	for view in interiors.views():
		if not view.is_ready() or view.plan.floors < BlockNav.LIFT_MIN_FLOORS:
			continue
		var k := view.floor_index_at(near - Vector3(0, WalkModel.EYE_HEIGHT, 0))
		var core := view.plan.core
		var local := Vector3(core.get_center().x, view.plan.floor_y(k) + 1.3, core.position.y + 0.2)
		result.append({"position": view.global_position + local, "label": "Lift · Fl %d of %d" % [k + 1, view.plan.floors],
			"kind": "lift", "payload": {"cell": view.cell, "floor": k}})
	return result


func _on_interacted(target: Dictionary) -> void:
	var payload: Dictionary = target.get("payload", {})
	if target.get("kind") == "door" and _is_hub_door(payload):
		open_hub(payload["cell"])
	elif target.get("kind") == "lift":
		open_lift(payload["cell"], payload["floor"])


## Offers the rides from the hub in a cell's district.
func open_hub(cell: Vector3i) -> void:
	var world := _world()
	var from := world.layout.district_of(cell)
	choices.clear()
	var lines := PackedStringArray()
	var jobs := _jobs()
	var has_pass := jobs != null and jobs.courier.has_tool("transit_pass")
	for to in TransitNetwork.links(from):
		var hub := network.hub_of(to)
		if hub.is_empty():
			continue
		choices.append({"kind": "hub", "from": from, "to": to, "hub": hub})
		var fare := 0 if has_pass else TransitNetwork.fare(from, to)
		var express := " (express)" if absi(to.y - from.y) >= TransitNetwork.EXPRESS_ROWS else ""
		lines.append("%s · %s%s · ¤%d" % [names.district_name(to), names.layer_label(hub["cell"].y), express, fare])
	_open("Transit hub · %s" % names.district_name(from), lines)


## Offers the floors a lift goes to.
func open_lift(cell: Vector3i, floor_index: int) -> void:
	var world := _world()
	var plan := world.population.plan_of(world.layout.block_at(cell))
	choices.clear()
	var lines := PackedStringArray()
	var options: Array[Array] = [["Ground floor", 0], ["Top floor", plan.floors - 1], ["Up 5 floors", floor_index + 5], ["Down 5 floors", floor_index - 5]]
	for option in options:
		var f: int = option[1]
		if f < 0 or f >= plan.floors or f == floor_index:
			continue
		choices.append({"kind": "lift", "cell": cell, "floor": f})
		lines.append("%s (Fl %d)" % [option[0], f + 1])
	_open("Lift", lines)


func _open(title: String, lines: PackedStringArray) -> void:
	var panel := _panel()
	if panel != null:
		panel.open(title, lines)


func _on_chosen(index: int) -> void:
	if index < 0 or index >= choices.size():
		choices.clear()
		return
	var choice := choices[index]
	choices.clear()
	if choice["kind"] == "hub":
		ride(choice["from"], choice["to"])
	else:
		lift(choice["cell"], choice["floor"])


## Rides from one district's hub to another's; false when the fare cannot be paid.
func ride(from: Vector3i, to: Vector3i) -> bool:
	var jobs := _jobs()
	var hub := network.hub_of(to)
	if hub.is_empty():
		return false
	var fare := 0 if jobs != null and jobs.courier.has_tool("transit_pass") else TransitNetwork.fare(from, to)
	if jobs != null:
		if jobs.courier.wallet.credits < fare:
			last_message = "The fare is ¤%d" % fare
			return false
		jobs.courier.wallet.credits -= fare
	var plan := _world().population.plan_of(_world().layout.block_at(hub["cell"]))
	var unit := plan.units[hub["unit"]]
	_place(hub["cell"], Vector3(unit.door_x, plan.floor_y(hub["floor"]) + 0.02, unit.front_z() + unit.front_sign * 1.5))
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	if session != null:
		session.clock.add_minutes(Economy.whole("transit", "ride_minutes"))
	last_message = "Rode to %s" % names.district_name(to)
	return true


## Takes the lift to a floor of the block in a cell.
func lift(cell: Vector3i, floor_index: int) -> void:
	var plan := _world().population.plan_of(_world().layout.block_at(cell))
	var core := plan.core
	_place(cell, Vector3(core.get_center().x, plan.floor_y(floor_index) + 0.02, core.position.y - 1.0))
	last_message = "Lift to floor %d" % (floor_index + 1)


func _place(cell: Vector3i, local: Vector3) -> void:
	var world := _world()
	var absolute := PackedFloat64Array()
	for axis in 3:
		absolute.append((cell[axis] + 0.5) * world.config.cell_size[axis] + local[axis])
	world.teleport_focus(absolute)
	world.prime_focus()
	var player := get_node_or_null(player_path) as Player if not player_path.is_empty() else null
	if player != null:
		player.velocity = Vector3.ZERO
		player.fall_guard.update(true, player.global_position, 1.0)


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _jobs() -> JobManager:
	return get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null


func _panel() -> DialoguePanel:
	return get_node_or_null(panel_path) as DialoguePanel if not panel_path.is_empty() else null
