class_name FirstContactStoryMap
extends Control

signal operation_requested(operation: StoryOperation)

const BACKPLATE := preload("res://assets/imported/first_contact/story_node_backplate.svg")
const ART_SIZE := Vector2(1280, 720)
var content: CampaignContent
var progress: CampaignProgress
var skin: FirstContactSkin
var _nodes := {}
var _labels := {}
var _detail: Label
var _map_rect: Rect2

func _ready() -> void:
	var rows: Array = skin.registration().story.nodes
	var focus: Button
	_detail = StoryUI.label("", 21, StoryUI.CREAM)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_detail)
	for row: Dictionary in rows:
		var operation := content.operation(StringName(row.id))
		if operation == null:
			continue
		var revealed := progress.is_visible(operation)
		var access := progress.access_error(operation)
		var record := progress.record_for(operation.stage.stage_id)
		var state := "node_fog"
		if revealed:
			state = "node_locked" if not access.is_empty() else "node_available"
			if record.get("cleared", false):
				state = "node_perfect" if record.get("perfect", false) else "node_cleared"
		var button := StoryUI.action(row.id)
		button.name = "Operation_" + row.id.replace("-", "_")
		button.disabled = not access.is_empty()
		button.flat = true
		button.icon = skin.region("interface", state)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.expand_icon = true
		button.set_meta("medallion", state)
		button.add_theme_color_override("font_color", StoryUI.CREAM)
		button.add_theme_color_override("font_disabled_color", StoryUI.INK)
		var label: String = row.title if revealed else "Requires Control Lv.%d" % operation.min_control_level
		var info: String = label + " · " + (access if not access.is_empty() and revealed else "")
		if access.is_empty():
			info = "%s · %s" % [label, "Perfect · Replay" if state == "node_perfect" else ("Cleared · Replay" if state == "node_cleared" else "Plan operation")]
			if focus == null or record.is_empty():
				focus = button
		button.tooltip_text = info.strip_edges().trim_suffix(" ·")
		button.mouse_entered.connect(_show_detail.bind(button))
		button.focus_entered.connect(_show_detail.bind(button))
		button.focus_exited.connect(_restore_icon.bind(button))
		button.pressed.connect(func() -> void: operation_requested.emit(operation))
		add_child(button)
		_nodes[row.id] = [button, FirstContactSkin.vector(row.ui_center_units)]
		if row.id.begins_with("C1"):
			_caption(label, Vector2(row.ui_center_units[0], 292), 0.17)
		elif int(String(row.id).get_slice("-", 1)) % 2 == 1:
			_caption(operation.region if revealed else "Fogged operations",
				FirstContactSkin.vector(row.ui_center_units) + Vector2(49, -79), 0.175)
	resized.connect(_layout)
	_layout()
	if focus != null:
		focus.grab_focus()

func _caption(text: String, center: Vector2, width: float) -> void:
	var caption := StoryUI.label(text, 15, StoryUI.INK)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(caption)
	_labels[caption] = [center, width]

func _show_detail(button: Button) -> void:
	_detail.text = button.tooltip_text
	if button.has_focus() and button.get_meta("medallion") == "node_available":
		button.icon = skin.region("interface", "node_selected")

func _restore_icon(button: Button) -> void:
	button.icon = skin.region("interface", button.get_meta("medallion"))

func _layout() -> void:
	var metrics := size / ART_SIZE
	_map_rect = Rect2(Vector2.ZERO, size)
	var touch := StoryUI.android_touch_minimum(self).max(Vector2.ONE * 76.0)
	for row: Array in _nodes.values():
		var button: Button = row[0]
		button.size = touch
		button.position = row[1] * metrics - button.size * 0.5
	for caption: Label in _labels:
		var row: Array = _labels[caption]
		caption.size = Vector2(size.x * float(row[1]), 36)
		caption.position = row[0] * metrics - caption.size * 0.5
	_detail.position = Vector2(38, size.y * 0.81)
	_detail.size = Vector2(maxf(0, size.x - 76), size.y * 0.14)
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(BACKPLATE, _map_rect, false)
	for row: Array in _nodes.values():
		var button: Button = row[0]
		if button.get_meta("medallion") == "node_fog":
			draw_texture_rect(skin.region("interface", "fog_band"), Rect2(button.position - Vector2(10, 4), button.size + Vector2(20, 8)), false)
