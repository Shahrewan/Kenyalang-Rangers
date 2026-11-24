extends VBoxContainer

signal back_requested
signal start_requested
signal access_requested
signal modifiers_requested

var plan: OperationPlan
var funds := 0
var _start: Button
var _feedback: Label
var _loadout: LoadoutPicker
var _modifier_summary: Label
var _fixed_labels: Dictionary[StringName, Label] = {}

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var operation := plan.operation
	var title := operation.title if plan.chaos else "%s   %s" % [operation.stage.stage_id, operation.title]
	StoryUI.header(self, title, func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(funds))
	var content := StoryUI.row(self, 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tactics := StoryUI.scroll_column(content)
	_loadout = LoadoutPicker.new()
	_loadout.plan = plan
	_loadout.selection_changed.connect(_refresh_plan)
	_loadout.selection_blocked.connect(show_error)
	_loadout.headquarters_requested.connect(func() -> void: access_requested.emit())
	tactics.add_child(_loadout)
	if operation.campaign_spec:
		_add_modifiers(tactics)
	else:
		_add_legacy_plan(tactics)

	var incoming := StoryUI.scroll_column(content)
	incoming.add_child(StoryUI.label("Incoming waves", 27))
	var intel := WaveIntel.new()
	incoming.add_child(intel)
	intel.show_stage(plan.resolved().stage)
	if operation.campaign_spec and not plan.chaos and not FirstContactSkin.is_pilot(operation.stage.stage_id):
		var assets := CampaignVisualAssets.new()
		var art := assets.region(operation.stage.map.map_id)
		if not art.is_empty():
			var field := TextureRect.new()
			field.texture = assets.texture(art.planning_thumbnail.texture)
			field.custom_minimum_size.y = 82
			field.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			field.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			field.mouse_filter = Control.MOUSE_FILTER_IGNORE
			incoming.add_child(field)
			incoming.move_child(field, intel.get_index())

	var footer := StoryUI.row(self, 16)
	_feedback = StoryUI.label("", 18, StoryUI.BEIGE)
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_feedback)
	_start = StoryUI.action("Start trial" if plan.chaos else "Start operation", true)
	_start.name = "StartOperation"
	_start.custom_minimum_size.x = 192
	_start.pressed.connect(_start_operation)
	footer.add_child(_start)
	_refresh_plan()

func _add_modifiers(parent: Control) -> void:
	var operation := plan.operation
	if not operation.fixed_debuff_ids.is_empty() or not operation.hints.is_empty():
		var fixed := StoryUI.panel(parent)
		for id in operation.fixed_debuff_ids:
			var definition := BattleModifiers.CATALOG.definition(id)
			fixed.add_child(StoryUI.label("%s · %s" % [id, definition.display_name], 21, StoryUI.AMBER))
			var details := StoryUI.label("", 17)
			fixed.add_child(details)
			_fixed_labels[id] = details
		if not operation.hints.is_empty():
			var hints := CheckBox.new()
			hints.text = "Show tutorial hints"
			hints.button_pressed = plan.show_hints
			hints.toggled.connect(func(enabled: bool) -> void: plan.show_hints = enabled)
			fixed.add_child(hints)

	var effects := StoryUI.panel(parent)
	_modifier_summary = StoryUI.label("", 18)
	effects.add_child(_modifier_summary)
	var edit := StoryUI.action("Edit modifiers")
	edit.name = "OpenModifiers"
	edit.pressed.connect(func() -> void: modifiers_requested.emit())
	effects.add_child(edit)

func _add_legacy_plan(parent: Control) -> void:
	var fixed := StoryUI.panel(parent)
	fixed.add_child(StoryUI.label(plan.operation.fixed_debuff, 21, StoryUI.AMBER))
	fixed.add_child(StoryUI.label("Fixed · Post yield reduced by %d%%" % (100 - plan.operation.opening_rules.yield_percent), 17))

	var effects := StoryUI.panel(parent)
	effects.add_child(StoryUI.label("R&D support · Choose up to one", 21))
	var options := OptionButton.new()
	options.name = "BuffSelector"
	options.custom_minimum_size.y = 52
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.fit_to_longest_item = false
	options.add_item("No buff selected")
	var buffs := plan.modifier_choices(true)
	var selected_index := 0
	for i in buffs.size():
		var item := buffs[i]
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
	effects.add_child(options)
	var details := StoryUI.label("", 17, StoryUI.BEIGE)
	details.name = "BuffDetails"
	effects.add_child(details)
	_update_legacy_note(details, buffs)
	options.item_selected.connect(func(index: int) -> void:
		var selection: BattleModifier = buffs[index - 1] if index > 0 else null
		if not plan.select_buff(selection):
			options.select(buffs.find(plan.selected_buff) + 1 if plan.selected_buff != null else 0)
		_update_legacy_note(details, buffs)
		_refresh_plan()
	)

func _update_legacy_note(view: Label, buffs: Array[BattleModifier]) -> void:
	if plan.selected_buff != null:
		view.text = plan.selected_buff.description
		return
	var eligible := buffs.any(func(buff: BattleModifier) -> bool: return plan.buff_error(buff).is_empty())
	view.text = "Select an unlocked effect or start without one." if eligible else "Open the list to inspect requirements."

func _refresh_plan() -> void:
	var result := plan.resolved()
	_start.disabled = not result.can_start()
	if plan.operation.campaign_spec:
		_refresh_modifiers(result)
		_loadout.refresh(result)
	if not result.selection_error.is_empty():
		_feedback.text = result.selection_error
	elif not result.opening_error.is_empty():
		_feedback.text = result.opening_error
		if plan.operation.campaign_spec and plan.facility_limit == 0 and not result.opening.fixed_stockpile:
			_feedback.text = "Build Mechanical to equip the Logistics Post, or use an eligible opening buff."
	else:
		_feedback.text = "Opening · %d Tokens" % result.tokens
		if result.entries.any(func(spec: DeploymentSpec) -> bool: return spec.logistics_post):
			_feedback.text += " · First Logistics Post free"

func _refresh_modifiers(result: ModifierResolution) -> void:
	for id: StringName in _fixed_labels:
		var description := BattleModifiers.CATALOG.definition(id).description
		if result.inactive_fixed.has(id):
			description += "\n" + result.inactive_fixed[id]
		_fixed_labels[id].text = description
	var selected := PackedStringArray()
	for modifier in BattleModifiers.CATALOG.entries:
		if plan.modifier_selected(modifier.id):
			selected.append(modifier.display_name)
	if plan.chaos:
		_modifier_summary.text = "Modifier trial · Fixed waves"
		if result.can_start():
			_modifier_summary.text += "\nModifier points %+d · %d Ranger / %d Facility slots filled" % [result.modifier_points(), result.ranger_slots, result.facility_slots]
	else:
		_modifier_summary.text = "R&D buffs · %d/%d" % [plan.modifier_count(true), plan.operation.optional_buff_limit]
	if not selected.is_empty():
		_modifier_summary.text += "\n" + ", ".join(selected)

func _start_operation() -> void:
	_refresh_plan()
	if not _start.disabled:
		start_requested.emit()

func show_error(message: String) -> void:
	_feedback.text = message
