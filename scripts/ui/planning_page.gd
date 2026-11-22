extends VBoxContainer

signal back_requested
signal start_requested

var plan: OperationPlan
var funds := 0
var _start: Button
var _feedback: Label

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var operation := plan.operation
	StoryUI.header(self, "%s   %s" % [operation.stage.stage_id, operation.title], func() -> void: back_requested.emit(), "%d Funds" % funds)
	var content := StoryUI.row(self, 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tactics := _scroll_column(content)
	var loadout := StoryUI.row(tactics, 10)
	var rangers := StoryUI.panel(loadout, true)
	rangers.add_child(StoryUI.label("Rangers", 24, StoryUI.INK))
	var facilities := StoryUI.panel(loadout, true)
	facilities.add_child(StoryUI.label("Facilities", 24, StoryUI.INK))
	for spec in plan.deployment_entries():
		if spec.is_ranger():
			rangers.add_child(StoryUI.label("%s · %d Tokens" % [spec.label, spec.cost], 18, StoryUI.INK))
		else:
			facilities.add_child(StoryUI.label("Starter Post · Free", 18, StoryUI.INK))
	facilities.add_child(StoryUI.label("Mission supply · Regular slots require Mechanical.", 16, StoryUI.INK))
	var fixed := StoryUI.panel(tactics)
	fixed.add_child(StoryUI.label(operation.fixed_debuff, 21, StoryUI.AMBER))
	fixed.add_child(StoryUI.label("Fixed · Post yield reduced by %d%%" % (100 - operation.opening_rules.yield_percent), 17))

	var effects := StoryUI.panel(tactics)
	effects.add_child(StoryUI.label("R&D support · Choose up to one", 21))
	var choices := StoryUI.row(effects, 10)
	var options := OptionButton.new()
	options.name = "BuffSelector"
	options.custom_minimum_size.y = 52
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.fit_to_longest_item = false
	options.add_item("No buff selected")
	var selected_index := 0
	for i in operation.buff_choices.size():
		var item := operation.buff_choices[i]
		var error := plan.buff_error(item)
		var name := item.display_name
		if not error.is_empty():
			name += " · " + error
		options.add_item(name)
		options.set_item_disabled(i + 1, not error.is_empty())
		if plan.selected_buff == item:
			selected_index = i + 1
	var row_height := StoryUI.android_touch_minimum(self).y
	options.get_popup().add_theme_constant_override("v_separation", maxi(12, ceili(row_height) - 24))
	options.select(selected_index)
	choices.add_child(options)
	var details := StoryUI.label("", 17, StoryUI.BEIGE)
	details.name = "BuffDetails"
	effects.add_child(details)
	_update_buff_note(details)
	options.item_selected.connect(func(index: int) -> void:
		var selection: PlanningBuff = operation.buff_choices[index - 1] if index > 0 else null
		if not plan.select_buff(selection):
			options.select(operation.buff_choices.find(plan.selected_buff) + 1 if plan.selected_buff != null else 0)
		_update_buff_note(details)
		_update_start()
	)

	var incoming := _scroll_column(content)
	incoming.add_child(StoryUI.label("Incoming waves", 27))
	var intel := WaveIntel.new()
	incoming.add_child(intel)
	intel.show_stage(operation.stage)

	var footer := StoryUI.row(self, 16)
	_feedback = StoryUI.label("", 18, StoryUI.BEIGE)
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_feedback)
	_start = StoryUI.action("Start operation", true)
	_start.name = "StartOperation"
	_start.custom_minimum_size.x = 192
	_start.pressed.connect(_start_operation)
	footer.add_child(_start)
	_update_start()

func _scroll_column(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var column := StoryUI.column(scroll, 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return column

func _update_buff_note(view: Label) -> void:
	if plan.selected_buff != null:
		view.text = plan.selected_buff.description
		return
	var eligible := plan.operation.buff_choices.filter(func(buff: PlanningBuff) -> bool: return plan.buff_error(buff).is_empty())
	view.text = "No eligible buffs unlocked. Open the list to inspect requirements." if eligible.is_empty() else "Select an unlocked effect or start without one."

func _update_start() -> void:
	_start.disabled = not plan.can_start()
	_feedback.text = "A free Starter Post fits an elevated pair. Opening balance 0 Tokens." if not _start.disabled else "Start requires an affordable legal deployment."

func _start_operation() -> void:
	_update_start()
	if not _start.disabled:
		start_requested.emit()
