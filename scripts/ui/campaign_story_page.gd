class_name CampaignStoryPage
extends VBoxContainer

signal back_requested
signal access_requested
signal operation_requested(operation: StoryOperation)

var content: CampaignContent
var progress: CampaignProgress
var _body: Control
var _toggle: Button
var _skin: FirstContactSkin
var _list_view := false

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var back := StoryUI.header(self, "Story Mode", func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	back.custom_minimum_size.y = 64
	var summary := StoryUI.row(self, 16)
	var control := StoryUI.label("Control Lv.%d" % progress.room_level(HeadquartersCatalog.CONTROL), 22, StoryUI.BEIGE)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(control)
	_skin = FirstContactSkin.new()
	if content.error.is_empty() and not _skin.registration().is_empty():
		_toggle = StoryUI.action("List view")
		_toggle.name = "ToggleStoryView"
		_toggle.custom_minimum_size = Vector2(148, 64)
		_toggle.pressed.connect(_switch_view)
		summary.add_child(_toggle)
	var access := StoryUI.action("Headquarters")
	access.name = "OpenHeadquarters"
	access.custom_minimum_size.y = 64
	access.pressed.connect(func() -> void: access_requested.emit())
	summary.add_child(access)
	if not content.error.is_empty():
		add_child(StoryUI.label(content.error, 22, StoryUI.AMBER))
		return
	_render_view()

func _switch_view() -> void:
	_list_view = not _list_view
	_toggle.text = "Map view" if _list_view else "List view"
	_render_view()

func _render_view() -> void:
	if is_instance_valid(_body):
		remove_child(_body)
		_body.queue_free()
	if not _list_view and not _skin.registration().is_empty():
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = SIZE_EXPAND_FILL
		scroll.follow_focus = true
		var map := FirstContactStoryMap.new()
		map.content = content
		map.progress = progress
		map.skin = _skin
		map.size_flags_horizontal = SIZE_EXPAND_FILL
		map.size_flags_vertical = SIZE_EXPAND_FILL
		map.operation_requested.connect(func(operation: StoryOperation) -> void: operation_requested.emit(operation))
		scroll.add_child(map)
		_body = scroll
		add_child(scroll)
		return
	var list := StoryUI.scroll_column(self)
	_body = list.get_parent() as Control
	var section: VBoxContainer
	var last_group := ""
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
		var name := "%s  ·  %s" % [id, operation.title] if revealed else String(id)
		var button := StoryUI.action("%s\n%s" % [name, status], gate.is_empty() and record.is_empty())
		button.name = "Operation_" + String(id).replace("-", "_")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 80
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not gate.is_empty()
		button.pressed.connect(func() -> void: operation_requested.emit(operation))
		section.add_child(button)
