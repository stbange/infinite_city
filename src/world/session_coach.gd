class_name SessionCoach
extends Node
## The first-night guide and the F4 session stats (specs first-night-guide, economy-tables):
## listens to the courier's actions and keeps both up to date.

@export var session_path: NodePath
@export var jobs_path: NodePath
@export var panel_path: NodePath
@export var shop_path: NodePath
@export var encounters_path: NodePath
@export var hazards_path: NodePath

var guide := FirstNightGuide.new()
var stats := PlayStats.new()
var stats_visible: bool = false
var _connected: bool = false
var _carried_before: int = 0
var _credits_before: int = 0


func _process(_delta: float) -> void:
	update()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F4:
		stats_visible = not stats_visible


func update() -> void:
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	if session == null or jobs == null:
		return
	if not _connected:
		_connect(session, jobs)
	stats.start(session.clock.total_minutes)
	var ordinary := 0
	for job in jobs.carried:
		if job.story_beat.is_empty():
			ordinary += 1
	if ordinary > _carried_before:
		for i in ordinary - _carried_before:
			stats.order_taken()
		guide.mark("order_taken")
	_carried_before = ordinary
	var shop := get_node_or_null(shop_path) as CourierShop if not shop_path.is_empty() else null
	if shop != null and shop.was_opened:
		guide.mark("shop_opened")


func _connect(session: GameSession, jobs: JobManager) -> void:
	jobs.delivered.connect(func(job: DeliveryJob) -> void:
		stats.delivered(job.paid if job.paid > 0 else CourierBoard.pay_for(job, session.clock.total_minutes), job.picked_minute, session.clock.total_minutes)
		guide.mark("delivered"))
	var panel := get_node_or_null(panel_path) as DialoguePanel if not panel_path.is_empty() else null
	if panel != null:
		panel.chosen.connect(func(_i: int) -> void: guide.mark("scene_answered"))
	var encounters := get_node_or_null(encounters_path) as EncounterDirector if not encounters_path.is_empty() else null
	if encounters != null:
		encounters.paid.connect(func(amount: int) -> void: stats.toll(amount))
	var hazards := get_node_or_null(hazards_path) as HazardDirector if not hazards_path.is_empty() else null
	if hazards != null:
		hazards.rescued.connect(func() -> void: stats.rescued())
	session.register_part("guide", guide.to_dict, guide.from_dict)
	_connected = true


func hud_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	var tip := guide.prompt(jobs.patron.name if jobs != null and jobs.patron != null else "")
	if not tip.is_empty():
		lines.append("→ " + tip)
	if stats_visible and session != null:
		lines.append_array(stats.lines(session.clock.total_minutes))
	return lines
