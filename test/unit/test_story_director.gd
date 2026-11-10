extends GutTest
## Spec story-director: Casting from the world, Beats.

var plot: Dictionary


func before_all() -> void:
	plot = StoryDirector.template()


func _each_template(check: Callable) -> void:
	for id in StoryDirector.TEMPLATES:
		plot = StoryDirector.template(id)
		check.call(id)
	plot = StoryDirector.template()


func test_every_template_is_complete() -> void:
	_each_template(func(id: String) -> void:
		var cast := _cast_for(2024)
		for role: String in plot["roles"]:
			assert_false((cast.get(role, {}) as Dictionary).is_empty(), "%s: role %s" % [id, role])
		_check_no_dead_ends(id)
		_check_slots(id, cast))


func test_choosing_a_template() -> void:
	var picked := {}
	for i in 12:
		var config := CityConfig.new()
		config.world_seed = 500 + i * 104729
		var layout := CityLayout.new(config)
		var id := StoryDirector.pick_template(CityChronicle.new(config), layout, SpawnFinder.find_on_foot(layout).cell)
		assert_has(StoryDirector.TEMPLATES, id)
		assert_eq(StoryDirector.pick_template(CityChronicle.new(config), CityLayout.new(config), SpawnFinder.find_on_foot(layout).cell), id)
		picked[id] = true
	assert_gt(picked.size(), 1, "different seeds tell different stories")


func _cast_for(seed_value: int) -> Dictionary:
	var config := CityConfig.new()
	config.world_seed = seed_value
	var layout := CityLayout.new(config)
	var population := Population.new(layout, null)
	var spawn := SpawnFinder.find_on_foot(layout)
	return StoryDirector.cast(population, CityChronicle.new(config), spawn.cell, null, plot)


func test_every_role_filled() -> void:
	var roles: Dictionary = plot["roles"]
	for i in 8:
		var cast := _cast_for(1000 + i * 7919)
		var used := {}
		for role: String in roles:
			assert_true(cast.has(role) and not (cast[role] as Dictionary).is_empty(), "seed %d role %s" % [i, role])
			if not cast.has(role) or (cast[role] as Dictionary).is_empty():
				continue
			var entry: Dictionary = cast[role]
			assert_false(used.has(entry["key"]), "%s cast twice" % entry["key"])
			used[entry["key"]] = true
			var spec: Dictionary = roles[role]
			if spec["kind"] == "person":
				assert_between(int(entry["age"]), int(spec["min_age"]), int(spec["max_age"]))


func test_deterministic_cast() -> void:
	assert_eq(JSON.stringify(_cast_for(4242)), JSON.stringify(_cast_for(4242)))


## Explores every sequence of deliveries (up to a bound) and choices.
func test_no_dead_ends() -> void:
	_check_no_dead_ends("hidden_abundance")


func _check_no_dead_ends(id: String) -> void:
	var start := StoryState.new()
	var states := {}
	var queue: Array = []
	var initial := _snapshot(start, 0)
	StoryDirector.begin(plot, start, 0)
	initial = _snapshot(start, 0)
	states[initial] = true
	queue.append([start, 0])
	var reached := {}
	var edges := {}   # snapshot -> Array of snapshots
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var state: StoryState = item[0]
		var deliveries: int = item[1]
		var key := _snapshot(state, deliveries)
		edges[key] = []
		for next: Array in _successors(state, deliveries):
			var s: StoryState = next[0]
			var d: int = next[1]
			for beat_id: String in s.done:
				reached[beat_id] = true
			var k := _snapshot(s, d)
			(edges[key] as Array).append(k)
			if not states.has(k):
				states[k] = true
				queue.append(next)
	for b: Dictionary in plot["beats"]:
		assert_true(reached.has(b["id"]), "%s: beat %s reachable" % [id, b["id"]])
	# From every state, the end of the story is reachable.
	var good := {}
	for k: String in states:
		if k.contains("story_done"):
			good[k] = true
	var changed := true
	while changed:
		changed = false
		for k: String in edges:
			if good.has(k):
				continue
			for n: String in edges[k]:
				if good.has(n):
					good[k] = true
					changed = true
					break
	for k: String in states:
		# States near the delivery bound may lack room to finish; judge the rest.
		if not good.has(k) and int(k.get_slice("|", 0)) <= 25:
			fail_test("%s dead end: %s" % [id, k])
			return
	assert_gt(states.size(), 10)


func _copy(state: StoryState) -> StoryState:
	var s := StoryState.new()
	s.from_dict(state.to_dict())
	return s


func _successors(state: StoryState, deliveries: int) -> Array:
	var result: Array = []
	if not state.scene.is_empty():
		for i in StoryDirector.choices(plot, state).size():
			var s := _copy(state)
			StoryDirector.choose(plot, s, i, deliveries)
			StoryDirector.begin(plot, s, deliveries)
			result.append([s, deliveries])
		return result
	if not state.job_role.is_empty():
		var s := _copy(state)
		StoryDirector.deliver_story_job(plot, s)
		result.append([s, deliveries + 1])
	if deliveries < 40:
		var s := _copy(state)
		StoryDirector.begin(plot, s, deliveries + 1)
		result.append([s, deliveries + 1])
	return result


func _snapshot(state: StoryState, deliveries: int) -> String:
	var done: Array = state.done.keys()
	done.sort()
	var flags: Array = state.flags.keys()
	flags.sort()
	return "%d|%s|%s|%s|%s|%s" % [deliveries, ",".join(done), ",".join(flags), state.active, state.scene, state.job_role]


func test_scenes_name_the_cast() -> void:
	_check_slots("hidden_abundance", _cast_for(1337))


func _check_slots(id: String, cast: Dictionary) -> void:
	var state := StoryState.new()
	state.cast = cast
	for scene_id: String in plot["scenes"]:
		state.scene = scene_id
		var raw := str(plot["scenes"][scene_id]["text"])
		var text := StoryDirector.scene_text(plot, state, 1)
		# An unfilled slot becomes "?": the filled text has no more of them than the template.
		assert_eq(text.count("?"), raw.count("?"), "%s: %s" % [scene_id, text])
		assert_false(text.contains("{"), text)
		var options: Array = StoryDirector.choices(plot, state)
		var texts := StoryDirector.choice_texts(plot, state, 1)
		for i in texts.size():
			assert_eq(texts[i].count("?"), str(options[i]["text"]).count("?"), texts[i])
	for b: Dictionary in plot["beats"]:
		state.active = b["id"]
		assert_false(StoryDirector.objective(plot, state).contains("?"), "%s: %s" % [id, b["id"]])
