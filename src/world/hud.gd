class_name Hud
extends CanvasLayer
## On-screen read-out (spec free-flight / Location read-out), colour legend and controls.

@export var world_path: NodePath
@export var camera_path: NodePath
@export var pocket_manager_path: NodePath

const _REFRESH_SECONDS := 0.1

var _label: Label
var _since_refresh: float = 0.0


func _ready() -> void:
	add_to_group(&"hud")
	_label = Label.new()
	_label.name = "Readout"
	_label.position = Vector2(16, 12)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	_build_legend()
	_build_controls()


func _process(delta: float) -> void:
	_since_refresh += delta
	if _since_refresh >= _REFRESH_SECONDS:
		_since_refresh = 0.0
		refresh()


func text() -> String:
	return _label.text


func refresh() -> void:
	var world := get_node_or_null(world_path) as CityWorld
	var camera := get_node_or_null(camera_path) as FlyCamera
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
	var pockets := get_node_or_null(pocket_manager_path) as PocketManager \
			if not pocket_manager_path.is_empty() else null
	if pockets != null and pockets.is_inside():
		lines = LocationInfo.describe_pocket(pockets.pocket_info())
	lines += "\nSpeed %d m/s  ·  %d chunks  ·  %d fps" % [
			roundi(camera.model.cruise_speed), world.loaded_chunks().size(), Engine.get_frames_per_second()]
	_label.text = lines


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
	hint.text = "Click: look around   WASD: fly   Space/E: up   Q/Ctrl: down   Shift: boost   Wheel: speed   Esc: release mouse"
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
