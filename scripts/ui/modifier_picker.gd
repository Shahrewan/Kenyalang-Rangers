class_name ModifierPicker
extends VBoxContainer

signal back_requested
signal apply_requested

var plan: OperationPlan
var confirm_changes := false
var _show_buffs := true
var _scroll: ScrollContainer
var _list: GridContainer
var _summary: Label
var _rows: Dictionary[StringName, CheckBox] = {}
var _reasons: Dictionary[StringName, Label] = {}
var _assets := CampaignVisualAssets.new()
var _buffs: Button
var _debuffs: Button

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var back := StoryUI.header(self, "Battle modifiers", func() -> void: back_requested.emit())
	back.name = "BackFromModifiers"
	if confirm_changes:
		back.text = "Cancel"
	if plan.chaos:
		var tabs := StoryUI.row(self)
		var group := ButtonGroup.new()
		_buffs = StoryUI.action("R&D buffs")
		_buffs.name = "ShowBuffs"
		_buffs.pressed.connect(_show_catalog.bind(true))
		tabs.add_child(_buffs)
		_debuffs = StoryUI.action("Debuffs")
		_debuffs.name = "ShowDebuffs"
		_debuffs.pressed.connect(_show_catalog.bind(false))
		tabs.add_child(_debuffs)
		for tab in [_buffs, _debuffs]:
			tab.toggle_mode = true
			tab.button_group = group
			tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tab.custom_minimum_size.y = 60.0
	_summary = StoryUI.label("", 20, StoryUI.AMBER)
	_summary.name = "ModifierSummary"
	add_child(_summary)
	var contents := StoryUI.scroll_column(self)
	_scroll = contents.get_parent() as ScrollContainer
	_scroll.scroll_deadzone = 12
	_list = GridContainer.new()
	_list.add_theme_constant_override("h_separation", 12)
	_list.add_theme_constant_override("v_separation", 12)
	_list.resized.connect(_resize_columns)
	contents.add_child(_list)
	if confirm_changes:
		var apply := StoryUI.action("Apply modifiers", true)
		apply.name = "ApplyModifiers"
		apply.custom_minimum_size.y = 70.0
		apply.pressed.connect(func() -> void: apply_requested.emit())
		add_child(apply)
	_show_catalog(true)

func _resize_columns() -> void:
	_list.columns = 2 if _list.size.x >= 1000.0 else 1

func _show_catalog(buffs: bool) -> void:
	_show_buffs = buffs
	if _buffs != null:
		_buffs.set_pressed_no_signal(buffs)
		_debuffs.set_pressed_no_signal(not buffs)
	for item in _list.get_children():
		_list.remove_child(item)
		item.queue_free()
	_rows.clear()
	_reasons.clear()
	_scroll.scroll_vertical = 0
	for modifier in plan.modifier_choices(buffs):
		_add_modifier(modifier)
	StoryUI.size_buttons(self)
	_refresh()

func _add_modifier(modifier: BattleModifier) -> void:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.theme_type_variation = &"LightPanel"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(card)
	var title := "%s · %s" % [modifier.id, modifier.display_name]
	if plan.chaos:
		title += " · %+d points" % modifier.chaos_points
	var check := CheckBox.new()
	check.mouse_filter = Control.MOUSE_FILTER_PASS
	check.name = "Modifier_" + String(modifier.id)
	check.accessibility_name = title
	check.accessibility_description = modifier.description
	check.custom_minimum_size.y = 70.0
	check.add_theme_stylebox_override("hover", get_theme_stylebox("hover", &"Button"))
	check.add_theme_stylebox_override("pressed", get_theme_stylebox("pressed", &"Button"))
	check.add_theme_stylebox_override("hover_pressed", get_theme_stylebox("hover_pressed", &"Button"))
	check.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	check.toggled.connect(_toggle.bind(modifier))
	card.add_child(check)
	# The content sets the card's size and passes every hit to the checkbox beneath it.
	var inset := MarginContainer.new()
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_theme_constant_override("margin_left", 34)
	inset.add_theme_constant_override("margin_top", 6)
	inset.add_theme_constant_override("margin_right", 10)
	inset.add_theme_constant_override("margin_bottom", 6)
	card.add_child(inset)
	var copy := StoryUI.column(inset, 4)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading := StoryUI.row(copy, 8)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := StoryUI.artwork(_assets.modifier_glyph(modifier.id), Vector2(26, 26))
	icon.name = "ModifierGlyph_" + String(modifier.id)
	heading.add_child(icon)
	var label := StoryUI.label(title, 20, StoryUI.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(label)
	var description := StoryUI.label(modifier.description, 18, StoryUI.INK)
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(description)
	var reason := StoryUI.label("", 17, Color("#6d4928"))
	reason.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(reason)
	_rows[modifier.id] = check
	_reasons[modifier.id] = reason

func _toggle(enabled: bool, modifier: BattleModifier) -> void:
	plan.set_modifier(modifier, enabled)
	_refresh()

func _refresh() -> void:
	var count := plan.modifier_count(_show_buffs)
	var selection := "%d selected" % count if plan.chaos else "%d / %d distinct buffs" % [count, plan.operation.optional_buff_limit]
	var current := plan.resolved()
	_summary.text = selection
	if not current.selection_error.is_empty():
		_summary.text += "   ·   " + current.selection_error
	elif plan.chaos and current.can_start():
		if confirm_changes:
			var score := ChaosScore.new(current)
			var points := score.points()
			_summary.text += "   ·   %s Medal Score   ·   %s Funds on qualifying victory" % [StoryUI.funds(points), StoryUI.funds(ChaosScore.payout(points))]
			if score.credited_debuff_points() < score.debuff_points:
				_summary.text += "\n" + ChaosComposer.debuff_credit_summary(score)
		else:
			_summary.text += "   ·   Modifier points %+d" % current.modifier_points()
	for id: StringName in _rows:
		var check := _rows[id]
		var selected := plan.modifier_selected(id)
		var reason := plan.modifier_error(BattleModifiers.CATALOG.definition(id))
		check.set_pressed_no_signal(selected)
		check.disabled = not selected and not reason.is_empty()
		_reasons[id].visible = check.disabled
		_reasons[id].text = reason
