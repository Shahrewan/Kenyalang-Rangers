extends VBoxContainer

signal back_requested
signal start_requested
signal access_requested

var plan: OperationPlan
var funds := 0
var _start: Button
var _feedback: Label
var _ranger_heading: Label
var _facility_heading: Label

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var operation := plan.operation
	StoryUI.header(self, "%s   %s" % [operation.stage.stage_id, operation.title], func() -> void: back_requested.emit(), "%d Funds" % funds)
	var content := StoryUI.row(self, 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tactics := StoryUI.scroll_column(content)
	var loadout := StoryUI.row(tactics, 10)
	var rangers := StoryUI.panel(loadout, true)
	_ranger_heading = StoryUI.label("Rangers", 24, StoryUI.INK)
	rangers.add_child(_ranger_heading)
	var facilities := StoryUI.panel(loadout, true)
	_facility_heading = StoryUI.label("Facilities", 24, StoryUI.INK)
	facilities.add_child(_facility_heading)
	if operation.campaign_spec:
		_add_campaign_loadout(rangers, facilities)
	else:
		for spec in plan.deployment_entries():
			if spec.is_ranger():
				rangers.add_child(StoryUI.label("%s · %d Tokens" % [spec.label, spec.cost], 18, StoryUI.INK))
			else:
				facilities.add_child(StoryUI.label("Starter Post · Free", 18, StoryUI.INK))
		facilities.add_child(StoryUI.label("Mission supply · Regular slots require Mechanical.", 16, StoryUI.INK))
	var fixed := StoryUI.panel(tactics)
	fixed.add_child(StoryUI.label(operation.fixed_debuff, 21, StoryUI.AMBER))
	if operation.campaign_spec:
		for id in operation.fixed_debuff_ids:
			fixed.add_child(StoryUI.label(CampaignDebuffs.DESCRIPTIONS[id], 17))
		if not operation.hints.is_empty():
			var hints := CheckBox.new()
			hints.text = "Show tutorial hints"
			hints.button_pressed = plan.show_hints
			hints.toggled.connect(func(enabled: bool) -> void: plan.show_hints = enabled)
			fixed.add_child(hints)
	else:
		fixed.add_child(StoryUI.label("Fixed · Post yield reduced by %d%%" % (100 - operation.opening_rules.yield_percent), 17))

	var effects := StoryUI.panel(tactics)
	var effect_limit := "Choose up to one" if operation.optional_buff_limit == 1 else "Up to %d distinct effects" % operation.optional_buff_limit
	effects.add_child(StoryUI.label("R&D support · " + effect_limit, 21))
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

	var incoming := StoryUI.scroll_column(content)
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

func _add_campaign_loadout(rangers: VBoxContainer, facilities: VBoxContainer) -> void:
	for spec in plan.deployment_entries():
		if spec.id not in plan.operation.supply_ids:
			continue
		var panel := rangers if spec.is_ranger() else facilities
		var price := "free first drop" if spec.logistics_post else "%d Tokens" % spec.cost
		var label := "Starter Post" if spec.logistics_post else spec.label
		panel.add_child(StoryUI.label("%s · %s\nMission supply" % [label, price], 18, StoryUI.INK))
	if plan.operation.opening_rules.starter_only:
		return
	for spec in plan.choices:
		var panel := rangers if spec.is_ranger() else facilities
		var choice := CheckBox.new()
		var price := "free first drop" if spec.logistics_post else "%d Tokens" % plan.effective_spec(spec).cost
		choice.text = "%s\n%s" % [spec.label, price]
		choice.add_theme_font_size_override("font_size", 16)
		choice.add_theme_color_override("font_color", StoryUI.INK)
		choice.add_theme_color_override("font_hover_color", StoryUI.INK)
		choice.add_theme_color_override("font_pressed_color", StoryUI.INK)
		choice.name = "Equip_" + String(spec.id).replace(".", "_")
		choice.button_pressed = spec.id in plan.selected_ids
		panel.add_child(choice)
		choice.toggled.connect(func(selected: bool) -> void:
			if not plan.select_unit(spec, selected):
				choice.set_pressed_no_signal(false)
				_feedback.text = "Remove an equipped %s to free a slot." % ("Ranger" if spec.is_ranger() else "Facility")
				return
			_update_slot_labels()
			_update_start()
		)
	if plan.facility_limit == 0:
		var access := StoryUI.action("Open Campaign access")
		facilities.add_child(access)
		access.pressed.connect(func() -> void: access_requested.emit())
	_update_slot_labels()

func _update_slot_labels() -> void:
	_ranger_heading.text = "Rangers · %d/%d" % [plan.selected_count(true), plan.ranger_limit]
	_facility_heading.text = "Facilities · %d/%d" % [plan.selected_count(false), plan.facility_limit]

func _update_buff_note(view: Label) -> void:
	if plan.selected_buff != null:
		view.text = plan.selected_buff.description
		return
	var eligible := plan.operation.buff_choices.filter(func(buff: PlanningBuff) -> bool: return plan.buff_error(buff).is_empty())
	view.text = "No eligible buffs unlocked. Open the list to inspect requirements." if eligible.is_empty() else "Select an unlocked effect or start without one."

func _update_start() -> void:
	_start.disabled = not plan.can_start()
	if _start.disabled:
		_feedback.text = "Start requires an affordable legal deployment."
		if plan.operation.campaign_spec and plan.facility_limit == 0:
			_feedback.text = "Build Mechanical in Campaign access to equip the Logistics Post."
	elif plan.operation.opening_rules.starter_only:
		_feedback.text = "Drag the free Starter Post onto an elevated pair. Opening balance 0 Tokens."
	elif plan.operation.opening_rules.fixed_stockpile:
		_feedback.text = "Fixed Stockpile · 120 Tokens"
	else:
		_feedback.text = "The first Logistics Post is free. Opening balance 0 Tokens."

func _start_operation() -> void:
	_update_start()
	if not _start.disabled:
		start_requested.emit()

func show_error(message: String) -> void:
	_feedback.text = message
