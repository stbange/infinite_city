class_name StoryDirector
extends RefCounted
## Plot templates cast from the world and run beat by beat (spec story-director): casting picks
## factions and residents around the start for the template's roles; beats start when their
## preconditions hold, wait for a scene choice or a story delivery, and change the story state.

const DEFAULT_TEMPLATE := "hidden_abundance"
const TEMPLATES: Array[String] = ["hidden_abundance", "election", "plague", "blackout", "fall_of_a_house", "descent"]
## Short arcs for regulars that run beside the main arc (spec story-director / Side arcs).
const SIDE_TEMPLATES: Array[String] = ["side_debt", "side_affair", "side_child"]
const SALT_SIDE := 192
const SALT_CAST := 190
const SALT_TEMPLATE := 191


static func template(id: String = DEFAULT_TEMPLATE) -> Dictionary:
	return DataTables.load_table("plot_" + id).data


## The template that fits the start best (spec plot-templates / Choosing a template): a base fit
## from the start's Reach plus a per-seed jitter, so seeds differ.
static func pick_template(chronicle: CityChronicle, layout: CityLayout, start: Vector3i) -> String:
	var reach := chronicle.reach(CityChronicle.reach_of(layout.district_of(start)))
	var year := CityHistory.PRESENT_YEAR
	var parties := 0
	var food := false
	var medicine := false
	var power := false
	var faith := false
	for f in reach.factions + chronicle.history.powers:
		if not f.exists_at(year):
			continue
		parties += 1 if f.type == "party" else 0
		food = food or (f.type == "company" and f.good == "food")
		medicine = medicine or (f.type == "company" and f.good == "medicine")
		power = power or (f.type == "company" and f.good == "power")
		faith = faith or f.type == "faith"
	var scores := {
		"hidden_abundance": 1.0 + (0.6 if food else 0.0),
		"election": 0.4 + 0.3 * mini(parties, 3),
		"plague": 0.8 + (0.6 if medicine else 0.0),
		"blackout": 0.7 + (0.6 if power else 0.0),
		"fall_of_a_house": 0.9,
		"descent": 0.6 + (0.6 if faith else 0.0),
	}
	var best := DEFAULT_TEMPLATE
	var best_score := -1.0
	for id in TEMPLATES:
		var score: float = scores[id] + DetHash.u01(DetHash.hash2(layout.config.world_seed, SALT_TEMPLATE, id.hash(), 0)) * 0.8
		if score > best_score:
			best = id
			best_score = score
	return best


## The side arc for a seed (one of SIDE_TEMPLATES, by hash).
static func pick_side(seed_value: int) -> String:
	return SIDE_TEMPLATES[DetHash.hash1(seed_value, SALT_SIDE, 0) % SIDE_TEMPLATES.size()]


# --- Casting -------------------------------------------------------------------------------

## Role -> entry for every role of the template. Person entries: kind, key, first, family, age,
## cell [x, y, z], floor, unit; the patron adds place (the workplace name); faction entries: kind,
## key, name. `patron` may be null (a resident then takes the role).
static func cast(population: Population, chronicle: CityChronicle, start: Vector3i, patron: WorkplaceInfo,
		plot: Dictionary = {}, exclude: Dictionary = {}) -> Dictionary:
	if plot.is_empty():
		plot = template()
	var roles: Dictionary = plot["roles"]
	var result := {}
	var used := exclude.duplicate()
	var role_names: Array = roles.keys()
	role_names.sort()
	if roles.has("patron"):
		result["patron"] = _cast_patron(population, start, patron, used)
	for role: String in role_names:
		var spec: Dictionary = roles[role]
		match str(spec["kind"]):
			"person":
				result[role] = _cast_person(population, start, spec, used, role)
			"faction":
				result[role] = _cast_faction(chronicle, population.layout, start, spec, used)
			"flat":
				result[role] = _cast_flat(population, start, spec, used)
	return result


static func _person_entry(person: PersonInfo, layout: CityLayout) -> Dictionary:
	var cell := person.id.cell(layout)
	return {"kind": "person", "key": person.id.key(), "first": person.given_name, "family": person.family_name,
		"age": person.age, "cell": [cell.x, cell.y, cell.z], "floor": person.id.floor_index(), "unit": person.id.unit_index()}


static func _cast_patron(population: Population, start: Vector3i, patron: WorkplaceInfo, used: Dictionary) -> Dictionary:
	if patron != null:
		var staff := population.job_market(patron.id.district).staff_of(patron)
		var boss: PersonInfo = null
		for id in staff:
			var p := population.person(id)
			if p != null and (boss == null or p.age > boss.age or (p.age == boss.age and p.id.key() < boss.id.key())):
				boss = p
		if boss != null:
			used[boss.id.key()] = true
			var entry := _person_entry(boss, population.layout)
			entry["place"] = patron.name
			entry["workplace"] = [patron.cell.x, patron.cell.y, patron.cell.z, patron.floor_index, patron.unit]
			return entry
	var fallback := _cast_person(population, start, {"min_age": 35, "max_age": 70, "radius": 4}, used, "patron")
	fallback["place"] = "the counter"
	return fallback


## The best resident of the housing blocks around the start for an age range: nearest block first,
## then a per-role hash order; nobody is cast twice.
static func _cast_person(population: Population, start: Vector3i, spec: Dictionary, used: Dictionary, role: String) -> Dictionary:
	var layout := population.layout
	var radius := int(spec.get("radius", 3))
	var lo := int(spec.get("min_age", 18))
	var hi := int(spec.get("max_age", 120))
	var salt := role.hash()
	for r in radius + 3:
		var best: PersonInfo = null
		var best_rank := 0
		for dy in range(-1, 2):
			for dx in range(-r, r + 1):
				for dz in range(-r, r + 1):
					if maxi(absi(dx), absi(dz)) != r:
						continue
					var block := layout.block_at(start + Vector3i(dx, dy, dz))
					if block == null or block.kind != BlockTypes.Kind.HOUSING:
						continue
					var people := population.block_people(block)
					for i in people.size():
						var age: int = people.ages[i]
						var id: PersonId = people.ids[i]
						if age < lo or age > hi or used.has(id.key()):
							continue
						var rank := DetHash.hash3(population.world_seed(), SALT_CAST, salt, id.local, id.district.x * 4096 + id.district.z)
						if best == null or rank < best_rank:
							best = population.person(id)
							best_rank = rank
		if best != null:
			used[best.id.key()] = true
			return _person_entry(best, layout)
	return {}


## A vacant flat near the start (on the layer `layer` below it), standing in for a place.
static func _cast_flat(population: Population, start: Vector3i, spec: Dictionary, used: Dictionary) -> Dictionary:
	var layout := population.layout
	var radius := int(spec.get("radius", 3))
	var centre := start + Vector3i(0, int(spec.get("layer", 0)), 0)
	for r in radius + 3:
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var cell := centre + Vector3i(dx, 0, dz)
				var block := layout.block_at(cell)
				if block == null or block.kind != BlockTypes.Kind.HOUSING:
					continue
				for flat in population.flats_of(block):
					var key := PersonId.of(layout, cell, flat.x, flat.y, 0).key()
					if used.has(key) or not population.household(cell, flat.x, flat.y).is_vacant():
						continue
					used[key] = true
					var name := str(spec.get("name", "the door"))
					return {"kind": "flat", "key": key, "first": name, "family": "", "name": name,
						"cell": [cell.x, cell.y, cell.z], "floor": flat.x, "unit": flat.y}
	return {}


static func _cast_faction(chronicle: CityChronicle, layout: CityLayout, start: Vector3i, spec: Dictionary, used: Dictionary) -> Dictionary:
	var types: Array = spec.get("types", [])
	var good := str(spec.get("good", ""))
	var reach := chronicle.reach(CityChronicle.reach_of(layout.district_of(start)))
	var year := CityHistory.PRESENT_YEAR
	var candidates: Array[FactionInfo] = []
	for f in reach.factions:
		if f.exists_at(year) and f.type in types and not used.has(f.key):
			candidates.append(f)
	for f in chronicle.history.powers:
		if f.exists_at(year) and f.type in types and not used.has(f.key):
			candidates.append(f)
	if candidates.is_empty():
		for f in reach.factions:
			if f.exists_at(year) and not used.has(f.key):
				candidates.append(f)
	if candidates.is_empty():
		return {}
	var best := candidates[0]
	for f in candidates:
		var fits := not good.is_empty() and f.good == good
		var best_fits := not good.is_empty() and best.good == good
		if (fits and not best_fits) or (fits == best_fits and f.strength > best.strength):
			best = f
	used[best.key] = true
	return {"kind": "faction", "key": best.key, "name": best.name}


# --- Beats ---------------------------------------------------------------------------------

static func beat(plot: Dictionary, id: String) -> Dictionary:
	for b: Dictionary in plot["beats"]:
		if b["id"] == id:
			return b
	return {}


static func _ready_to_start(b: Dictionary, state: StoryState, deliveries: int) -> bool:
	if state.done.has(b["id"]):
		return false
	for other: String in b.get("after", []):
		if not state.done.has(other):
			return false
	var any: Array = b.get("any", [])
	if not any.is_empty():
		var found := false
		for other: String in any:
			found = found or state.done.has(other)
		if not found:
			return false
	for flag: String in b.get("flags", []):
		if not state.flags.has(flag):
			return false
	if deliveries < int(b.get("deliveries", 0)):
		return false
	var since: Array = b.get("since", [])
	if since.size() == 2 and (not state.done.has(since[0]) or deliveries - int(state.done[since[0]]) < int(since[1])):
		return false
	return true


## Starts the first beat whose preconditions hold (when none is active); returns its id or "".
static func begin(plot: Dictionary, state: StoryState, deliveries: int) -> String:
	if not state.active.is_empty():
		return ""
	for b: Dictionary in plot["beats"]:
		if not _ready_to_start(b, state, deliveries):
			continue
		state.active = b["id"]
		state.job_role = ""
		state.meet_role = ""
		state.scene = ""
		match str(b["trigger"]):
			"job":
				state.job_role = (b["job"] as Dictionary)["to"]
			"meet":
				state.meet_role = b["meet"]
			_:
				state.scene = b["scene"]
		return state.active
	return ""


## The active beat's story delivery arrived: its scene opens.
static func deliver_story_job(plot: Dictionary, state: StoryState) -> void:
	if state.job_role.is_empty():
		return
	state.job_role = ""
	state.scene = beat(plot, state.active)["scene"]


## The courier met the person the active beat waits for: its scene opens.
static func met(plot: Dictionary, state: StoryState) -> void:
	if state.meet_role.is_empty():
		return
	state.meet_role = ""
	state.scene = beat(plot, state.active)["scene"]


## Choices of the open scene.
static func choices(plot: Dictionary, state: StoryState) -> Array:
	if state.scene.is_empty():
		return []
	return (plot["scenes"][state.scene] as Dictionary).get("choices", [])


## Picks a choice of the open scene and finishes the active beat; returns its effects:
## {heat: {gang key: amount}, wallet: credits, world: [effect names], kill: [person keys]}.
static func choose(plot: Dictionary, state: StoryState, index: int, deliveries: int) -> Dictionary:
	var effects := {"heat": {}, "wallet": 0, "world": [], "kill": []}
	if state.scene.is_empty():
		return effects
	var options := choices(plot, state)
	if index >= 0 and index < options.size():
		for flag: String in (options[index] as Dictionary).get("flags", []):
			state.flags[flag] = true
	var b := beat(plot, state.active)
	for flag: String in b.get("set_flags", []):
		state.flags[flag] = true
	state.act = maxi(state.act, int(b.get("act", state.act)))
	var heat: Dictionary = b.get("heat", {})
	for role: String in heat:
		var entry: Dictionary = state.cast.get(role, {})
		if entry.has("key"):
			effects["heat"][entry["key"]] = float(heat[role])
	effects["wallet"] = int(b.get("wallet", 0))
	effects["world"] = (b.get("world", []) as Array).duplicate()
	for role: String in b.get("kill", []):
		var entry: Dictionary = state.cast.get(role, {})
		if entry.get("kind") == "person":
			effects["kill"].append(entry["key"])
	state.done[state.active] = deliveries
	state.active = ""
	state.scene = ""
	return effects


# --- Text ----------------------------------------------------------------------------------

## Slot values: the cast plus the courier ({courier.first}; "courier" when nobody was named).
static func slot_values(state: StoryState, courier: Dictionary = {}) -> Dictionary:
	var values := state.cast.duplicate()
	var name := str(courier.get("name", "courier"))
	values["courier"] = {"first": name, "name": name, "pronouns": str(courier.get("pronouns", "they/them"))}
	return values


static func scene_text(plot: Dictionary, state: StoryState, seed_value: int, courier: Dictionary = {}) -> String:
	if state.scene.is_empty():
		return ""
	return TextTemplate.fill(str(plot["scenes"][state.scene]["text"]), slot_values(state, courier), seed_value + state.scene.hash())


static func choice_texts(plot: Dictionary, state: StoryState, seed_value: int, courier: Dictionary = {}) -> PackedStringArray:
	var result := PackedStringArray()
	for option: Dictionary in choices(plot, state):
		result.append(TextTemplate.fill(str(option["text"]), slot_values(state, courier), seed_value))
	return result


## The objective of the active beat (or the last finished one).
static func objective(plot: Dictionary, state: StoryState) -> String:
	var id := state.active
	if id.is_empty():
		var latest := ""
		for b: Dictionary in plot["beats"]:
			if state.done.has(b["id"]):
				latest = b["id"]
		id = latest
	if id.is_empty():
		return ""
	return TextTemplate.fill(str(beat(plot, id).get("objective", "")), state.cast, 0)
