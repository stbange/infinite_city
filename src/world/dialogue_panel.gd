class_name DialoguePanel
extends CanvasLayer
## A scene of the story (spec dialogue / Scene panel): the text with the cast's names filled in and
## numbered choices picked with the number keys.

signal chosen(index: int)

const WIDTH := 760.0

var _panel: PanelContainer
var _text: Label
var _choices: Label
var _count: int = 0


func _ready() -> void:
	layer = 5
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -WIDTH * 0.5
	_panel.offset_right = WIDTH * 0.5
	_panel.offset_top = -40.0
	_panel.offset_bottom = -40.0
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.1, 0.88)
	style.border_color = Color(0.95, 0.65, 0.25)
	style.set_border_width_all(0)
	style.border_width_left = 3
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(WIDTH - 40.0, 0)
	box.add_child(_text)
	_choices = Label.new()
	_choices.add_theme_color_override("font_color", Color(0.95, 0.75, 0.4))
	box.add_child(_choices)
	add_child(_panel)
	_panel.visible = false


func is_open() -> bool:
	return _panel != null and _panel.visible


func open(text: String, choices: PackedStringArray) -> void:
	_text.text = text
	var lines := PackedStringArray()
	for i in choices.size():
		lines.append("%d  %s" % [i + 1, choices[i]])
	_choices.text = "\n".join(lines)
	_count = choices.size()
	_panel.visible = true


func text() -> String:
	return _text.text + "\n" + _choices.text if _text != null else ""


func close() -> void:
	if _panel != null:
		_panel.visible = false


func choose(index: int) -> void:
	if not is_open() or index < 0 or index >= maxi(_count, 1):
		return
	_panel.visible = false
	chosen.emit(index)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_9:
		choose(key - KEY_1)
		get_viewport().set_input_as_handled()
