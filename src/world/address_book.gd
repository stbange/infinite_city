class_name AddressBook
extends Node
## The courier's address book (spec game-menus / Address book): M lists the patron, home and the
## story's people and places with their addresses.

@export var jobs_path: NodePath
@export var story_path: NodePath
@export var panel_path: NodePath


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_M:
		var panel := _panel()
		if panel != null and panel.is_open():
			panel.close()
		else:
			open()


func open() -> void:
	var panel := _panel()
	if panel != null:
		panel.open("Address book\n" + "\n".join(entries()), PackedStringArray())


func entries() -> PackedStringArray:
	var lines := PackedStringArray()
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	if jobs == null or jobs.names == null:
		return lines
	if jobs.patron != null:
		lines.append("%s (patron) · %s" % [jobs.patron.name, Address.format(jobs.names, jobs.patron.cell, jobs.patron.floor_index, jobs.patron.unit)])
	if not jobs.home.is_empty():
		lines.append("Home · %s" % Address.format(jobs.names, jobs.home["cell"], jobs.home["floor"], jobs.home["unit"]))
	var story := get_node_or_null(story_path) as StoryRunner if not story_path.is_empty() else null
	if story != null:
		var roles: Array = story.state.cast.keys()
		roles.sort()
		for role: String in roles:
			var entry: Dictionary = story.state.cast[role]
			if role == "patron" or not entry.has("cell"):
				continue
			var c: Array = entry["cell"]
			var who := ("%s %s" % [entry.get("first", ""), entry.get("family", "")]).strip_edges()
			lines.append("%s · %s" % [who, Address.format(jobs.names, Vector3i(int(c[0]), int(c[1]), int(c[2])), int(entry["floor"]), int(entry["unit"]))])
	return lines


func _panel() -> DialoguePanel:
	return get_node_or_null(panel_path) as DialoguePanel if not panel_path.is_empty() else null
