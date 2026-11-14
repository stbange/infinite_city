class_name SimulationRunner
extends Node
## Runs the live simulation (spec live-simulation): remembers the districts the courier walked
## in, ticks them once per game day into the event log, and shares the overlays with turf and jobs.

const MAX_CATCH_UP_DAYS := 7

@export var world_path: NodePath
@export var session_path: NodePath
@export var player_path: NodePath
@export var jobs_path: NodePath
@export var encounters_path: NodePath
@export var story_path: NodePath
## When false, update() must be called manually (used by tests).
@export var auto_update: bool = true

var log := EventLog.new()
var overlays := WorldOverlays.new()
var visited: Dictionary = {}   # district -> true
var ticked_day: int = -1
var _turf: TurfMap
var _registered: bool = false


func _process(_delta: float) -> void:
	if auto_update:
		update()


func update() -> void:
	var world := _world()
	var session := _session()
	if world == null or world.population == null or session == null:
		return
	_setup(world, session)
	var player := get_node_or_null(player_path) as Player if not player_path.is_empty() else null
	if player != null:
		visited[world.layout.district_of(world.origin.absolute_cell_of(player.global_position))] = true
	_apply_blackouts(world, session.clock.total_minutes)
	var today := session.clock.day_number()
	if ticked_day < 0:
		ticked_day = today
		return
	var first := maxi(ticked_day + 1, today - MAX_CATCH_UP_DAYS + 1)
	for day in range(first, today + 1):
		run_day(world, day)
	ticked_day = maxi(ticked_day, today)


## Ticks one day for every live district and applies its events.
func run_day(world: CityWorld, day: int) -> void:
	var districts: Array[Vector3i] = []
	for d: Vector3i in visited:
		districts.append(d)
	var story := get_node_or_null(story_path) as StoryRunner if not story_path.is_empty() else null
	var shortage := story != null and story.state.done.has("blight")
	var protected := {}
	if story != null:
		for role: String in story.state.cast:
			var entry: Dictionary = story.state.cast[role]
			if entry.get("kind") != "faction" and entry.has("key"):
				protected[entry["key"]] = true
	for event in LiveSimulation.tick(world.population, world.chronicle, overlays, _turf, day, districts, shortage, protected):
		log.events.append(event)
		overlays.apply(event)


## Districts dark right now, for the HUD and the windows (spec blackouts).
var dark_districts: Dictionary = {}
var _dark_applied: Dictionary = {}   # chunk view instance id -> dark set hash it shows


func _apply_blackouts(world: CityWorld, minute: int) -> void:
	var dark := {}
	for key: String in overlays.blackouts:
		var p := key.split(",")
		var district := Vector3i(int(p[0]), int(p[1]), int(p[2]))
		if overlays.is_dark(district, minute):
			dark[key] = true
	dark_districts = dark
	var stamp := dark.hash()
	for chunk in world.loaded_chunks():
		var view := world.chunk_view(chunk)
		if view == null or _dark_applied.get(view.get_instance_id(), 0) == stamp:
			continue
		view.set_blackout(world.layout, dark)
		_dark_applied[view.get_instance_id()] = stamp


func is_dark_at(world: CityWorld, cell: Vector3i) -> bool:
	return dark_districts.has(WorldOverlays.district_key(world.layout.district_of(cell)))


## Appends an event (from the story) and applies it.
func record(event: Dictionary, minute: int) -> void:
	var stored := event.duplicate(true)
	stored["minute"] = minute
	log.events.append(stored)
	overlays.apply(stored)


## How an ending rewrites the live area (spec plot-acts-3-to-5 / Endings change the district).
func story_effect(effect: String, cast: Dictionary, minute: int) -> void:
	var world := _world()
	if world == null:
		return
	if _turf == null:
		_turf = TurfMap.new(world.chronicle, world.layout)
		_turf.overlays = overlays
	var districts: Array[Vector3i] = []
	for d: Vector3i in visited:
		districts.append(d)
	var patron: Dictionary = cast.get("patron", {})
	var centre := Vector3i.ZERO
	if patron.has("cell"):
		var c: Array = patron["cell"]
		centre = Vector3i(int(c[0]), int(c[1]), int(c[2]))
		if not districts.has(world.layout.district_of(centre)):
			districts.append(world.layout.district_of(centre))
	match effect:
		"prices_fall", "prices_soar":
			for d in districts:
				record({"kind": "price", "district": WorldOverlays.district_key(d),
					"factor": 0.7 if effect == "prices_fall" else 2.5}, minute)
		"gang_takes_bridges":
			var gang: Dictionary = cast.get("disruptor", {})
			if not gang.has("key"):
				return
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					for bridge in world.layout.bridges_of(centre + Vector3i(dx, 0, dz)):
						if _turf.claim_of(bridge) != gang["key"]:
							record({"kind": "bridge_taken", "bridge": WorldOverlays.bridge_key(bridge),
								"gang": gang["key"], "from": _turf.claim_of(bridge)}, minute)


func _setup(world: CityWorld, session: GameSession) -> void:
	if _turf == null:
		_turf = TurfMap.new(world.chronicle, world.layout)
		_turf.overlays = overlays
	var encounters := get_node_or_null(encounters_path) as EncounterDirector if not encounters_path.is_empty() else null
	if encounters != null and encounters.turf != null and encounters.turf.overlays != overlays:
		encounters.turf.overlays = overlays
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	if jobs != null and jobs.overlays != overlays:
		jobs.overlays = overlays
	if not _registered:
		session.register_part("events", to_dict, from_dict)
		_registered = true


func to_dict() -> Dictionary:
	var districts: Array = []
	for d: Vector3i in visited:
		districts.append([d.x, d.y, d.z])
	return {"log": log.to_dict(), "visited": districts, "ticked": ticked_day}


func from_dict(data: Dictionary) -> void:
	log.from_dict(data.get("log", {}))
	overlays.rebuild(log)
	visited.clear()
	for d: Array in data.get("visited", []):
		visited[Vector3i(int(d[0]), int(d[1]), int(d[2]))] = true
	ticked_day = int(data.get("ticked", -1))


func _world() -> CityWorld:
	return get_node_or_null(world_path) as CityWorld if not world_path.is_empty() else null


func _session() -> GameSession:
	return get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
