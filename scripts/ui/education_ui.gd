class_name EducationUI
extends RefCounted

const ANSWER_HEIGHT := 72.0
const ACTION_HEIGHT := 64.0

static func activity_body(parent: VBoxContainer) -> Array[VBoxContainer]:
	var row := StoryUI.row(parent, 18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var context := StoryUI.scroll_column(row)
	context.get_parent().size_flags_stretch_ratio = 0.78
	var responses := StoryUI.scroll_column(row)
	responses.get_parent().size_flags_stretch_ratio = 1.22
	responses.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for content in [context, responses]:
		content.add_theme_constant_override("separation", 12)
		content.get_parent().scroll_deadzone = 12
	return [context, responses]

static func large_action(button: Button, height := ACTION_HEIGHT) -> Button:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, height)
	return button

static func answer_button(caption: String, name: String, callback: Callable) -> Button:
	var action := StoryUI.action("")
	action.name = name
	action.tooltip_text = caption
	action.accessibility_name = caption
	action.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var copy := StoryUI.label(caption, 20, StoryUI.INK)
	copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	copy.offset_left = 18
	copy.offset_right = -18
	copy.offset_top = 12
	copy.offset_bottom = -12
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_child(copy)
	var resize := func() -> void:
		var hit := StoryUI.android_touch_minimum(action)
		action.custom_minimum_size.y = maxf(maxf(hit.y, ANSWER_HEIGHT), copy.get_minimum_size().y + 24.0)
	copy.minimum_size_changed.connect(resize)
	action.resized.connect(resize)
	action.pressed.connect(callback)
	return action

static func receipt(change: int, discarded := 0) -> String:
	var text := "%s Funds credited" % StoryUI.funds(change)
	if change < 0:
		text = "%s Funds deducted" % StoryUI.funds(-change)
	if discarded > 0:
		text += "\n%s Funds discarded above the wallet cap." % StoryUI.funds(discarded)
	return text

static func credit_sources(parent: Container, catalog: EducationCatalog, ids: Array, color: Color) -> void:
	for citation in catalog.source_lines(ids):
		parent.add_child(StoryUI.label(citation, 16, color))

static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
