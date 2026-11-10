class_name Hud
extends CanvasLayer
## On-screen read-out (spec free-flight / Location read-out), colour legend and controls.

@export var world_path: NodePath
@export var camera_path: NodePath
@export var pocket_manager_path: NodePath
@export var interiors_path: NodePath
@export var interaction_path: NodePath:
	set(value):
		interaction_path = value
		_connect_interaction()
@export var session_path: NodePath

const _REFRESH_SECONDS := 0.1

var _label: Label
var _prompt: Label
var _debug: Label
var _card: Label
var _card_time: float = 0.0
var _connected: Interaction
var _since_refresh: float = 0.0


func _ready() -> void:
	add_to_group(&"hud")
	_label = Label.new()
	_label.name = "Readout"
	_label.position = Vector2(16, 12)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	_prompt = Label.new()
	_prompt.name = "Prompt"
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 0.62
	_prompt.anchor_bottom = 0.62
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	add_child(_prompt)
	_debug = Label.new()
	_debug.name = "DebugTimeline"
	_debug.anchor_left = 1.0
	_debug.anchor_right = 1.0
	_debug.offset_left = -560
	_debug.offset_right = -16
	_debug.offset_top = 12
	_debug.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_debug.add_theme_font_size_override("font_size", 12)
	_debug.add_theme_color_override("font_outline_color", Color.BLACK)
	_debug.add_theme_constant_override("outline_size", 4)
	_debug.visible = false
	add_child(_debug)
	_card = Label.new()
	_card.name = "Card"
	_card.anchor_left = 0.5
	_card.anchor_right = 0.5
	_card.anchor_top = 0.66
	_card.anchor_bottom = 0.66
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_theme_font_size_override("font_size", 15)
	_card.add_theme_color_override("font_outline_color", Color.BLACK)
	_card.add_theme_constant_override("outline_size", 6)
	add_child(_card)
	_build_legend()
	_build_controls()


func _process(delta: float) -> void:
	if _card_time > 0.0:
		_card_time -= delta
		if _card_time <= 0.0:
			_card.text = ""
	_since_refresh += delta
	if _since_refresh >= _REFRESH_SECONDS:
		_since_refresh = 0.0
		refresh()


func text() -> String:
	return _label.text


func debug_text() -> String:
	return _debug.text


func set_debug_visible(shown: bool) -> void:
	_debug.visible = shown


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		set_debug_visible(not _debug.visible)


func card_text() -> String:
	return _card.text


## Shows who lives or works behind an interacted door (spec residents / Residents card).
func show_card(target: Dictionary) -> void:
	var world := get_node_or_null(world_path) as CityWorld
	if world == null or world.population == null or target.get("kind") != "door":
		return
	var payload: Dictionary = target.get("payload", {})
	var cell: Vector3i = payload["cell"]
	var k: int = payload["floor"]
	var unit: int = payload["unit"]
	var population := world.population
	var lines := PackedStringArray()
	var block := world.layout.block_at(cell)
	if block != null and block.kind == BlockTypes.Kind.HOUSING:
		var people := population.residents(cell, k, unit)
		if people.is_empty():
			lines.append("Nobody lives here.")
		for p in people:
			var job := ""
			if population.has_job_market(p.id.district):
				var w := population.workplace_of(p.id)
				job = " · works at %s" % w.name if w != null else (" · out of work" if p.age >= 18 and p.age <= 67 else "")
			lines.append("%s, %d%s" % [p.full_name(), p.age, job])
		if not people.is_empty() and population.has_job_market(people[0].id.district) and world.gossip != null:
			var heard := world.gossip.about(people[0].id)
			lines.append("\"%s\"" % heard[0])
	else:
		var w := population.workplace(cell, k, unit)
		if w != null:
			var staff := ""
			if population.has_job_market(w.id.district):
				var market := population.job_market(w.id.district)
				var record := market.workplace_at(w.id)
				staff = " · %d staff" % market.staff_of(record).size()
			lines.append("%s (%s)%s · open %02d:00–%02d:00" % [w.name, w.trade, staff, w.opens / 60, (w.closes / 60) % 24])
	_card.text = "\n".join(lines)
	_card_time = 6.0


func _connect_interaction() -> void:
	if not is_inside_tree() or interaction_path.is_empty():
		return
	var interaction := get_node_or_null(interaction_path) as Interaction
	if interaction != null and interaction != _connected:
		_connected = interaction
		interaction.interacted.connect(show_card)


func prompt_text() -> String:
	return _prompt.text


## Shows "E · <label>" for the current interaction target (spec interaction / Prompt).
func refresh_prompt() -> void:
	var interaction := get_node_or_null(interaction_path) as Interaction if not interaction_path.is_empty() else null
	_connect_interaction()
	var target := interaction.target() if interaction != null else {}
	_prompt.text = "" if target.is_empty() else "E · %s" % target.get("label", "")


func refresh() -> void:
	refresh_prompt()
	var world := get_node_or_null(world_path) as CityWorld
	var camera := get_node_or_null(camera_path) as Player
	if world == null or camera == null or world.layout == null:
		return
	var cell := world.origin.absolute_cell_of(camera.global_position)
	var kind := BlockTypes.NONE
	var block := world.layout.block_at(cell)
	if block != null:
		var local := world.origin.offset_in_cell(camera.global_position) - world.config.cell_size * 0.5
		if AABB(block.min_local(), block.size).has_point(local):
			kind = block.kind
	var lines := LocationInfo.describe(world.layout, cell, kind)
	if world.chronicle != null:
		var district := world.layout.district_of(world.origin.absolute_cell_of(camera.global_position - Vector3(0, 0.1, 0)))
		var reach := world.chronicle.reach(CityChronicle.reach_of(district))
		var owner := world.chronicle.faction(world.chronicle.owner_of_district(district))
		if owner != null:
			lines += "\nTurf: %s · %s" % [owner.name, reach.name]
		if _debug.visible:
			_debug.text = _timeline(world.chronicle, reach)
	var pockets := get_node_or_null(pocket_manager_path) as PocketManager \
			if not pocket_manager_path.is_empty() else null
	if pockets != null and pockets.is_inside():
		lines = LocationInfo.describe_pocket(pockets.pocket_info())
	var interiors := get_node_or_null(interiors_path) as InteriorManager \
			if not interiors_path.is_empty() else null
	var inside := interiors.view_at(camera.global_position) if interiors != null else null
	if inside != null:
		lines += "\n" + LocationInfo.describe_interior(inside.floor_index_at(camera.global_position),
				inside.plan.floors, inside.room_at(camera.global_position))
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	if session != null:
		lines = session.clock.describe() + "\n" + lines
	var moving := "Walking" if camera.mode == Player.Mode.WALK else "Flying %d m/s" % roundi(camera.model.cruise_speed)
	lines += "\n%s  ·  %d chunks  ·  %d fps" % [moving, world.loaded_chunks().size(), Engine.get_frames_per_second()]
	_label.text = lines


## The Reach's living factions and latest events (spec faction-traces / Debug timeline).
static func _timeline(chronicle: CityChronicle, reach: ReachHistory) -> String:
	var lines := PackedStringArray()
	lines.append("%s %s" % [reach.name, reach.reach])
	for faction in reach.factions:
		if faction.exists_at(CityHistory.PRESENT_YEAR):
			lines.append("  %s (%s, since %d)" % [faction.name, faction.type, faction.founded])
	var first := maxi(0, reach.events.size() - 14)
	for i in range(first, reach.events.size()):
		lines.append("%d  %s" % [reach.events[i].year, reach.events[i].text])
	return "\n".join(lines)


func _build_legend() -> void:
	var box := VBoxContainer.new()
	box.name = "Legend"
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 16
	box.offset_top = -16 - 20 * BlockTypes.Kind.size()
	box.add_theme_constant_override("separation", 2)
	for kind: int in BlockTypes.Kind.values():
		var row := HBoxContainer.new()
		var swatch := ColorRect.new()
		swatch.color = BlockTypes.color(kind)
		swatch.custom_minimum_size = Vector2(14, 14)
		var name_label := Label.new()
		name_label.text = BlockTypes.display_name(kind)
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)
		name_label.add_theme_constant_override("outline_size", 4)
		row.add_child(swatch)
		row.add_child(name_label)
		box.add_child(row)
	add_child(box)


func _build_controls() -> void:
	var hint := Label.new()
	hint.name = "Controls"
	hint.text = "Click: look   WASD: move   E: interact   Space: jump / up   Shift: sprint / boost   F: walk ⇄ fly   Q/Ctrl: down (fly)   Wheel: fly speed   Esc: release mouse"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 4)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.offset_left = -16
	hint.offset_right = -16
	hint.offset_top = -32
	hint.offset_bottom = -12
	add_child(hint)
