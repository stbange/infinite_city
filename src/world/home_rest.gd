class_name HomeRest
extends Node
## Sleeping at home (spec release-candidate / Save slots): E at the courier's own door sleeps until
## 07:00, recharges the lamp and saves the game in the "autosave" slot.

const WAKE_MINUTE := 7 * 60
const SLOT := "autosave"

@export var session_path: NodePath
@export var jobs_path: NodePath
@export var interaction_path: NodePath
@export var lamp_path: NodePath

var last_message: String = ""
var _connected: bool = false


func _process(_delta: float) -> void:
	if _connected:
		return
	var interaction := get_node_or_null(interaction_path) as Interaction if not interaction_path.is_empty() else null
	if interaction != null:
		interaction.interacted.connect(_on_interacted)
		interaction.add_label_hook(_label_for)
		_connected = true


func _is_home(payload: Dictionary) -> bool:
	var jobs := get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null
	return jobs != null and not jobs.home.is_empty() and payload.get("cell") == jobs.home["cell"] \
			and payload.get("floor") == jobs.home["floor"] and payload.get("unit") == jobs.home["unit"]


func _label_for(target: Dictionary) -> String:
	return "Home · sleep until morning" if target.get("kind") == "door" and _is_home(target.get("payload", {})) else ""


func _on_interacted(target: Dictionary) -> void:
	if target.get("kind") == "door" and _is_home(target.get("payload", {})):
		sleep()


## Sleeps until the next 07:00 and saves; returns "" or the save problem.
func sleep() -> String:
	var session := get_node_or_null(session_path) as GameSession if not session_path.is_empty() else null
	if session == null:
		return "no session"
	var day := session.clock.day_number()
	var wake := day * GameClock.MINUTES_PER_DAY + WAKE_MINUTE
	if wake <= session.clock.total_minutes:
		wake += GameClock.MINUTES_PER_DAY
	session.clock.total_minutes = wake
	var lamp := get_node_or_null(lamp_path) as CourierLamp if not lamp_path.is_empty() else null
	if lamp != null:
		lamp.recharge()
	var problem := session.save_to_slot(SLOT)
	last_message = "You sleep until 07:00. Game saved." if problem.is_empty() else "You sleep until 07:00. Saving failed: " + problem
	return problem
