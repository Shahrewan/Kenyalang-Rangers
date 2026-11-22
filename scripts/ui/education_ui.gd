class_name EducationUI
extends RefCounted

static func answer_button(caption: String, name: String, callback: Callable) -> Button:
	var action := StoryUI.action("")
	action.name = name
	action.tooltip_text = caption
	var copy := StoryUI.label(caption, 20, StoryUI.INK)
	copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	copy.offset_left = 14
	copy.offset_right = -14
	copy.offset_top = 7
	copy.offset_bottom = -7
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_child(copy)
	var resize := func() -> void:
		var hit := StoryUI.android_touch_minimum(action)
		action.custom_minimum_size.y = maxf(hit.y, copy.get_minimum_size().y + 14.0)
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
