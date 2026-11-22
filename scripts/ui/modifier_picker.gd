class_name ModifierPicker
extends VBoxContainer

signal back_requested

var plan: OperationPlan
var _show_buffs := true
var _list: VBoxContainer
var _summary: Label
var _rows: Dictionary[StringName, CheckBox] = {}
var _reasons: Dictionary[StringName, Label] = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	StoryUI.header(self, "Battle modifiers", func() -> void: back_requested.emit())
	if plan.chaos:
		var tabs := StoryUI.row(self)
		var buffs := StoryUI.action("R&D buffs")
		buffs.name = "ShowBuffs"
		buffs.pressed.connect(_show_catalog.bind(true))
		tabs.add_child(buffs)
		var debuffs := StoryUI.action("Debuffs")
		debuffs.name = "ShowDebuffs"
		debuffs.pressed.connect(_show_catalog.bind(false))
		tabs.add_child(debuffs)
	_summary = StoryUI.label("", 20, StoryUI.AMBER)
	_summary.name = "ModifierSummary"
	add_child(_summary)
	_list = StoryUI.scroll_column(self)
	_show_catalog(true)

func _show_catalog(buffs: bool) -> void:
	_show_buffs = buffs
	for item in _list.get_children():
		_list.remove_child(item)
		item.queue_free()
	_rows.clear()
	_reasons.clear()
	for modifier in plan.modifier_choices(buffs):
		var card := StoryUI.panel(_list, true)
		var check := CheckBox.new()
		check.name = "Modifier_" + String(modifier.id)
		check.text = "%s · %s" % [modifier.id, modifier.display_name]
		if plan.chaos:
			check.text += " · %+d points" % modifier.chaos_points
		check.add_theme_color_override("font_color", StoryUI.INK)
		check.add_theme_color_override("font_hover_color", StoryUI.INK)
		check.add_theme_color_override("font_pressed_color", StoryUI.INK)
		check.add_theme_color_override("font_disabled_color", Color("#5f6253"))
		check.toggled.connect(_toggle.bind(modifier))
		card.add_child(check)
		card.add_child(StoryUI.label(modifier.description, 18, StoryUI.INK))
		var reason := StoryUI.label("", 17, Color("#6d4928"))
		card.add_child(reason)
		_rows[modifier.id] = check
		_reasons[modifier.id] = reason
	StoryUI.size_buttons(self)
	_refresh()

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
		_summary.text += "   ·   Modifier points %+d" % current.modifier_points()
	for id: StringName in _rows:
		var check := _rows[id]
		var selected := plan.modifier_selected(id)
		var reason := plan.modifier_error(BattleModifiers.CATALOG.definition(id))
		check.set_pressed_no_signal(selected)
		check.disabled = not selected and not reason.is_empty()
		_reasons[id].visible = check.disabled
		_reasons[id].text = reason
