class_name CourierShop
extends Node
## The Couriers' Mutual shop (spec courier-progression / Shop): U opens it; the number keys buy a
## tool or the next licence.

@export var jobs_path: NodePath
@export var panel_path: NodePath

var last_message: String = ""
## True once the shop has been opened (the first-night guide).
var was_opened: bool = false
var _connected: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_U:
		toggle()


func toggle() -> void:
	var panel := _panel()
	if panel == null:
		return
	if panel.is_open():
		panel.close()
	else:
		open()


func open() -> void:
	var panel := _panel()
	var jobs := _jobs()
	if panel == null or jobs == null:
		return
	if not _connected:
		panel.chosen.connect(_on_chosen)
		_connected = true
	was_opened = true
	panel.open(heading(), entries())


func heading() -> String:
	var jobs := _jobs()
	return "Couriers' Mutual · %s licence · standing %d (%s) · ¤%d%s" % [jobs.courier.licence, jobs.courier.reputation.of(Reputation.MUTUAL),
			jobs.courier.reputation.level(Reputation.MUTUAL), jobs.courier.wallet.credits, ("\n" + last_message) if not last_message.is_empty() else ""]


func entries() -> PackedStringArray:
	var jobs := _jobs()
	var lines := PackedStringArray()
	for tool in ShopCatalogue.ORDER:
		var spec: Dictionary = ShopCatalogue.TOOLS[tool]
		var owned := int(jobs.courier.tools.get(tool, 0))
		var state := ""
		if owned > 0:
			state = " · owned" if not spec["consumable"] else " · %d held" % owned
		lines.append("%s · ¤%d · %s licence%s" % [spec["label"], ShopCatalogue.price(tool), spec["licence"], state])
	var next := Licence.next_level(jobs.courier.licence)
	if next.is_empty():
		lines.append("Licence: gold, the highest")
	else:
		var need: Dictionary = Licence.REQUIREMENTS[next]
		lines.append("Upgrade to %s licence · ¤%d · needs Mutual standing %d" % [next, need["fee"], need["mutual"]])
	lines.append("Light rights (free passage at Authority checkpoints) · ¤%d · silver licence%s" % [
		Economy.whole("licences", "light_rights_fee"), " · held" if jobs.courier.light_rights else ""])
	return lines


func _on_chosen(index: int) -> void:
	var jobs := _jobs()
	if index < ShopCatalogue.ORDER.size():
		var tool := ShopCatalogue.ORDER[index]
		last_message = ("Bought: %s" % tool) if jobs.courier.buy(tool) else ("Can't buy the %s yet" % tool)
	elif index == ShopCatalogue.ORDER.size() + 1:
		last_message = "Light rights granted" if jobs.courier.buy_light_rights() else "Light rights need a silver licence and the fee"
	elif jobs.courier.upgrade_licence():
		last_message = "Licence upgraded to %s" % jobs.courier.licence
	else:
		last_message = "The Mutual says: not yet"


func _jobs() -> JobManager:
	return get_node_or_null(jobs_path) as JobManager if not jobs_path.is_empty() else null


func _panel() -> DialoguePanel:
	return get_node_or_null(panel_path) as DialoguePanel if not panel_path.is_empty() else null
