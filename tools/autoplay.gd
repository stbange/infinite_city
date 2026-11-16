extends SceneTree
## Headless autoplay (developer tool): a scripted courier plays a session of real play time through
## the game's own rules — the courier board and rivals, walking routes at walking pace, doorsteps,
## gang tolls and Authority checkpoints on the bridges it crosses, the main plot and a side arc,
## rent, licences and the daily live simulation — and writes the story it lived as Markdown.
##
## scripts/godot.sh --headless --path . -s res://tools/autoplay.gd -- <seed> <persona> <real minutes> <out.md>
## Personas: dutiful (says yes, pays), rebel (refuses, runs), talker (talks first, picks by hash),
## drifter (picks by hash, pays or runs by hash).
##
## Simplifications against the live game: the courier walks the nav route instead of steering a
## body, a chase ends by a seeded coin toss instead of a footrace, and a meeting happens on arrival
## at the person's current door.

const WALK_SPEED := BalanceSim.WALK_SPEED
const DOOR_OVERHEAD := BalanceSim.DOOR_OVERHEAD
## Real seconds a player spends reading a scene, at a door, at a gang.
const READ_SCENE := 40.0
const READ_DOOR := 6.0
const READ_ENCOUNTER := 15.0
const SLEEP_FROM := 23 * 60 + 30
const WAKE := 7 * 60

var seed_value := 1337
var persona := "dutiful"
var real_budget := 3600.0
var out_path := "autoplay.md"

var population: Population
var chronicle: CityChronicle
var layout: CityLayout
var nav: CityNav
var board: CourierBoard
var routines: Routines
var turf: TurfMap
var overlays := WorldOverlays.new()
var log := EventLog.new()
var heat := Heat.new()
var courier := CourierState.new()

var minute := 0.0
var real := 0.0
var completed := 0
var carried: Array[DeliveryJob] = []
var here: NavPlace
var counter: NavPlace
var home: NavPlace
var patron: WorkplaceInfo
var visited := {}
var ticked_day := -1
var plots: Array[Dictionary] = []    # {plot, state, side}
var lines: PackedStringArray = []
var stats := {"deliveries": 0, "earned": 0, "tips": 0, "story_jobs": 0, "scenes": 0, "tolls": 0, "toll_paid": 0,
	"talked_through": 0, "chases": 0, "caught": 0, "checkpoints": 0, "confiscated": 0, "metres": 0.0,
	"rent_paid": 0, "nights": 0, "deaths": 0, "doors": {}}
var _rng_counter := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 4:
		seed_value = int(args[0])
		persona = args[1]
		real_budget = float(args[2]) * 60.0
		out_path = args[3]
	_setup()
	_play()
	_write()
	quit()


# --- Setup ---------------------------------------------------------------------------------

func _setup() -> void:
	var config := CityConfig.new()
	config.world_seed = seed_value
	layout = CityLayout.new(config)
	population = Population.new(layout, null)
	chronicle = CityChronicle.new(config)
	nav = CityNav.new(population)
	board = CourierBoard.new(population)
	routines = Routines.new(population)
	turf = TurfMap.new(chronicle, layout)
	turf.overlays = overlays
	var spawn := SpawnFinder.find_on_foot(layout).cell
	var start := StartScenario.find(population, spawn)
	patron = start["patron"]
	counter = NavPlace.door(patron.cell, patron.floor_index, patron.unit)
	if start.has("home_cell"):
		home = NavPlace.door(start["home_cell"], int(start["home_floor"]), int(start["home_unit"]))
	else:
		home = counter
	here = home
	var clock := GameClock.new_game()
	minute = clock.total_minutes
	courier.wallet.start(clock)
	visited[layout.district_of(patron.cell)] = true
	ticked_day = clock.day_number()
	var template_id := StoryDirector.pick_template(chronicle, layout, patron.cell)
	var main_plot := StoryDirector.template(template_id)
	var main_state := StoryState.new()
	main_state.template_id = template_id
	main_state.cast = StoryDirector.cast(population, chronicle, patron.cell, patron, main_plot)
	plots.append({"plot": main_plot, "state": main_state, "side": false})
	var exclude := {}
	for role: String in main_state.cast:
		exclude[main_state.cast[role].get("key", "")] = true
	var side_id := StoryDirector.pick_side(seed_value)
	var side_plot := StoryDirector.template(side_id)
	var side_state := StoryState.new()
	side_state.template_id = side_id
	side_state.cast = StoryDirector.cast(population, chronicle, patron.cell, null, side_plot, exclude)
	plots.append({"plot": side_plot, "state": side_state, "side": true})
	_head("# Seed %d · %s · %d real minutes" % [seed_value, persona, roundi(real_budget / 60.0)])
	_say("Courier works for **%s** (%s). Main plot: **%s** (%s). Side arc: **%s**." % [
		patron.name, _addr(counter), main_plot.get("title", template_id), template_id, side_plot.get("title", side_id)])
	var cast_text: PackedStringArray = []
	for p: Dictionary in plots:
		var st: StoryState = p["state"]
		for role: String in st.cast:
			cast_text.append("%s = %s" % [role, _cast_name(st.cast[role])])
	_say("Cast: " + ", ".join(cast_text))


# --- Main loop -----------------------------------------------------------------------------

func _play() -> void:
	while real < real_budget:
		_daily()
		var clock := GameClock.at(int(minute))
		if clock.minute_of_day() >= SLEEP_FROM or clock.minute_of_day() < 5 * 60:
			_sleep()
			continue
		_advance_stories()
		if _open_scenes():
			continue
		var meet := _pending_meet()
		if not meet.is_empty():
			_go_meet(meet)
			continue
		_take_orders()
		if carried.is_empty():
			# Nothing to carry this hour: wait at the counter for the next hour's orders.
			var next := (floorf(minute / 60.0) + 1.0) * 60.0
			_spend_game(next - minute)
			continue
		_run_bag()
	_say("")
	_head("## End of session")
	_say("%s · ¤%d · licence %s · reputation %d (%s)" % [
		GameClock.at(int(minute)).describe(), courier.wallet.credits, courier.licence,
		courier.reputation.of(Reputation.MUTUAL), courier.reputation.level(Reputation.MUTUAL)])
	for p: Dictionary in plots:
		var st: StoryState = p["state"]
		var done: Array = st.done.keys()
		_say("%s: act %d, beats done: %s%s" % [p["plot"].get("title", st.template_id), st.act, ", ".join(done),
			("; waiting on " + st.active) if not st.active.is_empty() else ""])


func _spend_game(game_minutes: float) -> void:
	minute += game_minutes
	real += game_minutes / GameClock.DEFAULT_SPEED


func _spend_real(seconds: float) -> void:
	real += seconds
	minute += seconds * GameClock.DEFAULT_SPEED


func _daily() -> void:
	var clock := GameClock.at(int(minute))
	var before := courier.wallet.credits
	courier.wallet.update(clock)
	if courier.wallet.credits < before:
		stats["rent_paid"] += before - courier.wallet.credits
		_event("Rent of ¤%d is due: ¤%d left." % [before - courier.wallet.credits, courier.wallet.credits])
	var today := clock.day_number()
	if today <= ticked_day:
		return
	var districts: Array[Vector3i] = []
	for d: Vector3i in visited:
		districts.append(d)
	var protected := {}
	var shortage := false
	for p: Dictionary in plots:
		var st: StoryState = p["state"]
		shortage = shortage or st.done.has("blight")
		for role: String in st.cast:
			if st.cast[role].get("kind") != "faction" and st.cast[role].has("key"):
				protected[st.cast[role]["key"]] = true
	for day: int in range(ticked_day + 1, today + 1):
		for event in LiveSimulation.tick(population, chronicle, overlays, turf, day, districts, shortage, protected):
			log.events.append(event)
			overlays.apply(event)
			_world_event(event)
	ticked_day = today


func _sleep() -> void:
	if not here.equals(home):
		_walk_to(home, "home")
	var clock := GameClock.at(int(minute))
	var wake := clock.day_number() * GameClock.MINUTES_PER_DAY + WAKE
	if wake <= minute:
		wake += GameClock.MINUTES_PER_DAY
	minute = wake
	real += 20.0
	stats["nights"] += 1
	_head("### Day %d · %s" % [GameClock.at(int(minute)).day_number() - GameClock.new_game().day_number() + 1, GameClock.at(int(minute)).describe()])
	_say("Slept at home. ¤%d in the wallet." % courier.wallet.credits)


# --- Courier work --------------------------------------------------------------------------

func _take_orders() -> void:
	if not here.equals(counter):
		_walk_to(counter, "the counter")
	var clock := GameClock.at(int(minute))
	var offers := board.offers(patron, clock.day_number(), clock.hour(), Licence.max_tier(courier.licence))
	for i in offers.size():
		var job := offers[i]
		if carried.size() >= JobManager.MAX_CARRIED:
			break
		var rival := board.rival_minute(patron, clock.day_number(), clock.hour(), i)
		if rival >= 0 and clock.minute() >= rival:
			continue
		if _taken.has(job.id):
			continue
		_taken[job.id] = true
		job.picked_minute = int(minute)
		carried.append(job)
	for p: Dictionary in plots:
		var st: StoryState = p["state"]
		if not st.job_role.is_empty():
			_ensure_story_job(p)

var _taken := {}


func _ensure_story_job(p: Dictionary) -> void:
	var st: StoryState = p["state"]
	var job_id := ("side:" if p["side"] else "story:") + st.active
	for job in carried:
		if job.id == job_id:
			return
	var entry: Dictionary = st.cast.get(st.job_role, {})
	if entry.is_empty():
		return
	var spec: Dictionary = StoryDirector.beat(p["plot"], st.active)["job"]
	var job := DeliveryJob.new()
	job.id = job_id
	job.story_beat = st.active
	job.pickup = patron.id
	job.patron_name = patron.name
	var c: Array = entry["cell"]
	job.dropoff_cell = Vector3i(int(c[0]), int(c[1]), int(c[2]))
	job.dropoff_floor = int(entry["floor"])
	job.dropoff_unit = int(entry["unit"])
	job.customer = PersonId.from_key(entry["key"])
	job.customer_name = ("%s %s" % [entry["first"], entry["family"]]).strip_edges()
	job.cargo = str(spec.get("cargo", "parcel"))
	job.cargo_kind = str(spec.get("kind", "food"))
	job.base_pay = StoryRunner.STORY_PAY
	job.picked_minute = int(minute)
	carried.insert(0, job)
	_say("Picked up a story delivery: %s for %s." % [job.cargo, job.customer_name])


func _run_bag() -> void:
	while not carried.is_empty() and real < real_budget:
		var job := carried[0]
		var door := NavPlace.door(job.dropoff_cell, job.dropoff_floor, job.dropoff_unit)
		if not _walk_to(door, job.customer_name):
			continue    # the bag was lost on the way
		if not carried.has(job):
			continue
		_deliver(job)
		_advance_stories()
		_open_scenes()


func _deliver(job: DeliveryJob) -> void:
	carried.erase(job)
	var answer := DoorstepRules.answer(population, routines, job.customer, int(minute))
	if overlays.is_dead(job.customer.key()):
		answer = {"state": "left", "tip": 0.3, "line": "Nobody answers. A neighbour says %s died this week." % job.customer_name}
	job.paid = CourierBoard.pay_for(job, int(minute), float(answer["tip"]))
	courier.wallet.credits += job.paid
	completed += 1
	stats["deliveries"] += 1
	stats["earned"] += job.paid
	stats["tips"] += job.paid - job.base_pay
	stats["doors"][answer["state"]] = int(stats["doors"].get(answer["state"], 0)) + 1
	courier.reputation.add(Reputation.MUTUAL, Reputation.DELIVERY if job.story_beat.is_empty() else Reputation.STORY_DELIVERY)
	_spend_real(READ_DOOR)
	var story := not job.story_beat.is_empty()
	if story:
		stats["story_jobs"] += 1
		for p: Dictionary in plots:
			var st: StoryState = p["state"]
			if job.story_beat == st.active and job.id.begins_with("side:" if p["side"] else "story:"):
				StoryDirector.deliver_story_job(p["plot"], st)
	# Doorstep lines: every story delivery, and an occasional ordinary one for colour.
	if story or _hash_u("door", completed) < 0.25:
		_say("%s → %s (%s): *%s* ¤%d" % [_time(), job.customer_name, job.cargo, str(answer["line"]), job.paid])
	if Licence.can_upgrade(courier.licence, courier.reputation, courier.wallet.credits) and courier.wallet.credits > 1200:
		var level := Licence.next_level(courier.licence)
		if courier.upgrade_licence():
			_event("Bought the %s licence." % level)


## Walks the route to a place, meeting gangs and checkpoints on its bridges. False when the bag
## was lost on the way.
func _walk_to(place: NavPlace, label: String) -> bool:
	var route := nav.route(here, place, CityNav.MAX_CELLS, 20000)
	var metres := 0.0
	var crossings: Array[BridgeInfo] = []
	if route.is_empty():
		metres = (Vector3(here.cell) * layout.config.cell_size).distance_to(Vector3(place.cell) * layout.config.cell_size) * BalanceSim.FALLBACK_DETOUR
	else:
		metres = route.length
		var last := Vector3i(route.nodes[0].x, route.nodes[0].y, route.nodes[0].z) if not route.nodes.is_empty() else here.cell
		for node: Vector4i in route.nodes:
			var cell := Vector3i(node.x, node.y, node.z)
			if cell != last:
				var b := _bridge(last, cell)
				if b != null:
					crossings.append(b)
				last = cell
	metres += DOOR_OVERHEAD
	stats["metres"] += metres
	var total := metres / WALK_SPEED * GameClock.DEFAULT_SPEED
	var step := total / float(crossings.size() + 1)
	for b in crossings:
		_spend_game(step)
		if not _cross(b):
			_spend_game(step)
			return false
	_spend_game(step)
	here = place
	return true


func _bridge(a: Vector3i, b: Vector3i) -> BridgeInfo:
	var d := b - a
	if d.y != 0 or absi(d.x) + absi(d.z) != 1:
		return null
	for candidate in layout.bridges_of(a):
		if (candidate.cell_a == a and candidate.cell_b == b) or (candidate.cell_a == b and candidate.cell_b == a):
			return candidate
	return null


## A bridge crossing with cargo: checkpoint or gang. False when the cargo was lost.
func _cross(b: BridgeInfo) -> bool:
	if carried.is_empty():
		return true
	var hour := int(minute) / 60
	if EncounterRules.is_checkpoint(seed_value, b, layout.config.roof_layer):
		var check := EncounterRules.checkpoint(carried, courier.light_rights)
		if check["kind"] == "pass":
			return true
		stats["checkpoints"] += 1
		_spend_real(READ_ENCOUNTER)
		var price: int = check["price"]
		var refuse := persona == "rebel" or (persona == "drifter" and _hash_u("check", hour) < 0.4)
		if check["kind"] == "contraband" and refuse:
			var taken := 0
			for job: DeliveryJob in carried.duplicate():
				if CargoKind.is_contraband(job.cargo_kind):
					carried.erase(job)
					taken += 1
			stats["confiscated"] += taken
			_event("Authority checkpoint: refused the bribe, %d package(s) confiscated." % taken)
			return not carried.is_empty()
		var paid := clampi(courier.wallet.credits, 0, price)
		courier.wallet.credits -= paid
		_event("Authority checkpoint (%s): paid ¤%d." % [check["kind"], paid])
		return true
	var claim := turf.claim_of(b)
	if claim.is_empty():
		return true
	var h := heat.value_at(claim, int(minute)) + CargoKind.total_heat(carried)
	var standing := courier.reputation.level(claim)
	var outcome := EncounterRules.roll(seed_value, b, hour, carried.size(), h)
	if outcome == "pass" or standing == "trusted":
		return true
	var gang := turf.gang(claim)
	var gang_name := gang.name if gang != null else "a gang"
	var price := EncounterRules.toll(carried.size(), h) * (2 if outcome == "shakedown" else 1)
	if standing == "friendly":
		price = roundi(price * EncounterDirector.FRIENDLY_DISCOUNT)
	stats["tolls"] += 1
	_spend_real(READ_ENCOUNTER)
	var verb := "shake you down" if outcome == "shakedown" else "want a toll"
	if persona == "talker" or (persona == "drifter" and _hash_u("talk", hour) < 0.3):
		if EncounterRules.talk_succeeds(seed_value, b, hour, heat.value_at(claim, int(minute))):
			stats["talked_through"] += 1
			_event("%s %s (¤%d); talked my way past." % [gang_name, verb, price])
			return true
		price *= 2
		verb += ", talking only doubled it"
	var run := persona == "rebel" or (persona == "drifter" and _hash_u("run", hour) < 0.35) \
			or (courier.wallet.credits < price and persona != "dutiful")
	if not run:
		var paid := clampi(courier.wallet.credits, 0, price)
		courier.wallet.credits -= paid
		stats["toll_paid"] += paid
		if paid < price:
			heat.add(claim, EncounterRules.SHORT_HEAT, int(minute))
		else:
			courier.reputation.add(claim, Reputation.TOLL_PAID)
		_event("%s %s: paid ¤%d." % [gang_name, verb, paid])
		return true
	heat.add(claim, EncounterRules.RUN_HEAT, int(minute))
	courier.reputation.add(claim, Reputation.RAN)
	stats["chases"] += 1
	if _hash_u("chase", hour * 7 + stats["chases"]) < 0.4:
		var lost := carried.size()
		carried.clear()
		var taken := clampi(courier.wallet.credits, 0, price)
		courier.wallet.credits -= taken
		courier.reputation.add(claim, Reputation.CAUGHT)
		stats["caught"] += 1
		_event("%s %s (¤%d). Ran — and was caught: %d orders and ¤%d gone." % [gang_name, verb, price, lost, taken])
		return false
	_event("%s %s (¤%d). Ran and lost them in the fog." % [gang_name, verb, price])
	return true


# --- Stories -------------------------------------------------------------------------------

func _advance_stories() -> void:
	for p: Dictionary in plots:
		var st: StoryState = p["state"]
		if st.active.is_empty():
			var started := StoryDirector.begin(p["plot"], st, completed)
			if not started.is_empty():
				var objective := StoryDirector.objective(p["plot"], st)
				_say("%s *%s — new objective:* %s" % [_time(), "Side" if p["side"] else "Story", objective])


func _open_scenes() -> bool:
	var any := false
	for p: Dictionary in plots:
		var st: StoryState = p["state"]
		while not st.scene.is_empty():
			any = true
			_play_scene(p)
			StoryDirector.begin(p["plot"], st, completed)
			if not st.active.is_empty():
				_say("%s *%s — new objective:* %s" % [_time(), "Side" if p["side"] else "Story", StoryDirector.objective(p["plot"], st)])
	return any


func _play_scene(p: Dictionary) -> void:
	var st: StoryState = p["state"]
	var plot: Dictionary = p["plot"]
	var profile := {"name": "Courier", "pronouns": "they/them"}
	var text := StoryDirector.scene_text(plot, st, seed_value, profile)
	var options := StoryDirector.choice_texts(plot, st, seed_value, profile)
	var pick := _choose(st, options)
	stats["scenes"] += 1
	_spend_real(READ_SCENE)
	_say("")
	_say("> **%s — %s** (act %d)  " % [_time(), "Side" if p["side"] else "Story", maxi(st.act, int(StoryDirector.beat(plot, st.active).get("act", st.act)))])
	_say("> " + text + "  ")
	if options.size() > 1:
		var others: PackedStringArray = []
		for i in options.size():
			if i != pick:
				others.append(options[i])
		_say("> → chose **%s** (not: %s)" % [options[pick], " / ".join(others)])
	elif options.size() == 1:
		_say("> → %s" % options[0])
	_say("")
	var effects := StoryDirector.choose(plot, st, pick, completed)
	var heat_fx: Dictionary = effects["heat"]
	for gang: String in heat_fx:
		heat.add(gang, heat_fx[gang], int(minute))
	if int(effects["wallet"]) != 0:
		courier.wallet.credits += int(effects["wallet"])
		_event("Wallet %+d." % int(effects["wallet"]))
	for key: String in effects["kill"]:
		var event := {"kind": "death", "person": key, "minute": int(minute)}
		log.events.append(event)
		overlays.apply(event)
		_event("%s is dead." % _person_name(key))
	for effect: String in effects["world"]:
		_story_effect(effect, st.cast)


func _choose(st: StoryState, options: PackedStringArray) -> int:
	if options.size() <= 1:
		return 0
	match persona:
		"dutiful":
			return 0
		"rebel":
			return options.size() - 1
		_:
			return int(_hash_u("choice:" + st.active + st.scene, 0) * options.size()) % options.size()


func _pending_meet() -> Dictionary:
	for p: Dictionary in plots:
		var st: StoryState = p["state"]
		if not st.meet_role.is_empty():
			return p
	return {}


func _go_meet(p: Dictionary) -> void:
	var st: StoryState = p["state"]
	var entry: Dictionary = st.cast.get(st.meet_role, {})
	if not entry.has("cell"):
		st.meet_role = ""
		return
	var c: Array = entry["cell"]
	var place := NavPlace.door(Vector3i(int(c[0]), int(c[1]), int(c[2])), int(entry["floor"]), int(entry["unit"]))
	var id := PersonId.from_key(entry["key"])
	var step := routines.at(id, int(minute))
	var where := "at home"
	if not step.walking and step.place.where == NavPlace.Where.UNIT:
		place = NavPlace.door(step.place.cell, step.place.floor_index, step.place.unit)
		where = step.activity
	_walk_to(place, _cast_name(entry))
	_say("%s Found %s (%s) at %s." % [_time(), _cast_name(entry), where, _addr(place)])
	StoryDirector.met(p["plot"], st)


func _story_effect(effect: String, cast: Dictionary) -> void:
	var districts: Array[Vector3i] = []
	for d: Vector3i in visited:
		districts.append(d)
	match effect:
		"prices_fall", "prices_soar":
			for d in districts:
				var event := {"kind": "price", "district": WorldOverlays.district_key(d), "factor": 0.7 if effect == "prices_fall" else 2.5, "minute": int(minute)}
				log.events.append(event)
				overlays.apply(event)
			_event("Food prices %s across the district." % ("fall" if effect == "prices_fall" else "soar"))
		"gang_takes_bridges":
			var gang: Dictionary = cast.get("disruptor", {})
			if not gang.has("key"):
				return
			var taken := 0
			for dx in range(-2, 3):
				for dz in range(-2, 3):
					for bridge in layout.bridges_of(patron.cell + Vector3i(dx, 0, dz)):
						if turf.claim_of(bridge) != gang["key"]:
							var event := {"kind": "bridge_taken", "bridge": WorldOverlays.bridge_key(bridge), "gang": gang["key"], "from": turf.claim_of(bridge), "minute": int(minute)}
							log.events.append(event)
							overlays.apply(event)
							taken += 1
			_event("%s take %d bridges around the counter." % [gang.get("name", "A gang"), taken])
		_:
			_event("World: %s." % effect)


# --- Text ----------------------------------------------------------------------------------

func _world_event(event: Dictionary) -> void:
	match str(event.get("kind")):
		"death":
			stats["deaths"] += 1
			_event("News: %s died." % _person_name(str(event["person"])))
		"moved", "move":
			_event("News: %s moved away." % _person_name(str(event.get("person", ""))))
		"bridge_taken":
			var gang := turf.gang(str(event.get("gang", "")))
			_event("News: %s took a bridge%s." % [gang.name if gang != null else "a gang",
				(" from " + turf.gang(str(event["from"])).name) if turf.gang(str(event.get("from", ""))) != null else ""])
		"blackout":
			_event("News: a blackout is announced for district %s." % str(event.get("district")))
		"price":
			if absf(float(event.get("factor", 1.0)) - 1.0) > 0.15:
				_event("News: food prices now ×%.2f." % float(event.get("factor", 1.0)))
		_:
			pass


func _person_name(key: String) -> String:
	if key.is_empty():
		return "someone"
	var p := population.person(PersonId.from_key(key))
	return p.full_name() if p != null else key


func _cast_name(entry: Dictionary) -> String:
	match str(entry.get("kind", "")):
		"person":
			var who := population.person(PersonId.from_key(entry["key"]))
			var extra := " (%d, %s)" % [int(entry.get("age", 0)), who.skill if who != null else ""]
			return ("%s %s" % [entry["first"], entry["family"]]).strip_edges() + extra
		"faction":
			return str(entry.get("name", "?"))
		"flat":
			return str(entry.get("name", "a flat"))
	return "nobody"


func _addr(place: NavPlace) -> String:
	return "cell %s fl %d unit %d" % [place.cell, place.floor_index, place.unit]


func _time() -> String:
	var c := GameClock.at(int(minute))
	return "`Day %d %02d:%02d`" % [c.day_number() - GameClock.new_game().day_number() + 1, c.hour(), c.minute()]


func _event(text: String) -> void:
	_say("%s %s" % [_time(), text])


func _say(text: String) -> void:
	lines.append(text)


func _head(text: String) -> void:
	lines.append("")
	lines.append(text)
	lines.append("")


func _hash_u(tag: String, n: int) -> float:
	return DetHash.u01(DetHash.hash2(seed_value, tag.hash(), n, persona.hash()))


func _write() -> void:
	var s := stats.duplicate()
	s["metres"] = roundi(s["metres"])
	s["real_minutes"] = roundi(real / 60.0)
	s["game_hours"] = snappedf((minute - GameClock.new_game().total_minutes) / 60.0, 0.1)
	s["credits"] = courier.wallet.credits
	_say("")
	_say("Stats: " + JSON.stringify(s))
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("wrote %s: %s" % [out_path, JSON.stringify(s)])
