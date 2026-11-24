class_name CampaignStoryPage
extends VBoxContainer

signal back_requested
signal access_requested
signal operation_requested(operation: StoryOperation)

var content: CampaignContent
var progress: CampaignProgress

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var profile := progress.snapshot()
	StoryUI.header(self, "Story Mode", func() -> void: back_requested.emit(), "%d Funds" % profile.funds)
	var summary := StoryUI.row(self, 16)
	var control := StoryUI.label("Control Lv.%d" % progress.room_level(HeadquartersCatalog.CONTROL), 22, StoryUI.BEIGE)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(control)
	var access := StoryUI.action("Headquarters")
	access.name = "OpenHeadquarters"
	access.pressed.connect(func() -> void: access_requested.emit())
	summary.add_child(access)
	if not content.error.is_empty():
		add_child(StoryUI.label(content.error, 22, StoryUI.AMBER))
		return
	var skin := FirstContactSkin.new()
	if not skin.registration().is_empty():
		var map := FirstContactStoryMap.new()
		map.content = content
		map.progress = progress
		map.skin = skin
		map.size_flags_vertical = SIZE_EXPAND_FILL
		map.operation_requested.connect(func(operation: StoryOperation) -> void: operation_requested.emit(operation))
		add_child(map)
		return
	var list := StoryUI.scroll_column(self)
	var section: VBoxContainer
	var last_group := ""
	var focus: Button
	for operation in content.operations:
		var revealed := progress.is_visible(operation)
		var group := operation.region if revealed else "Fogged operations"
		if group != last_group:
			section = StoryUI.panel(list)
			section.add_child(StoryUI.label(group, 25, StoryUI.AMBER))
			last_group = group
		var id := operation.stage.stage_id
		var gate := progress.access_error(operation)
		var record := progress.record_for(id)
		var status := gate
		if gate.is_empty():
			if record.get("perfect", false):
				status = "Perfect · Replay"
			elif record.get("cleared", false):
				status = "Cleared · Replay"
			else:
				status = "Plan operation"
		var row := StoryUI.row(section)
		var name := "%s   %s" % [id, operation.title] if revealed else String(id)
		var button := StoryUI.action(name, gate.is_empty() and record.is_empty())
		button.name = "Operation_" + String(id).replace("-", "_")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not gate.is_empty()
		button.pressed.connect(func() -> void: operation_requested.emit(operation))
		row.add_child(button)
		var info := StoryUI.label(status, 18, StoryUI.BEIGE)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		info.custom_minimum_size.x = 184
		row.add_child(info)
		if not button.disabled and (focus == null or record.is_empty()):
			focus = button
	if focus != null:
		focus.grab_focus()
