class_name ChaosWaveEditor
extends VBoxContainer

signal changed

var configuration: ChaosConfiguration
var slot := 0
var _tabs: Array[Button] = []
var _title: Label
var _entries: VBoxContainer
var _sliders: Dictionary[StringName, HSlider] = {}
var _quantities: Dictionary[StringName, Label] = {}
var _down: Dictionary[StringName, Button] = {}
var _up: Dictionary[StringName, Button] = {}

func _ready() -> void:
	add_theme_constant_override("separation", 9)
	var bar := StoryUI.row(self, 6)
	var group := ButtonGroup.new()
	for index in ChaosConfiguration.WAVE_SLOTS:
		var tab := StoryUI.action("")
		tab.name = "WaveSlot%d" % (index + 1)
		tab.toggle_mode = true
		tab.button_group = group
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(_select_slot.bind(index))
		_tabs.append(tab)
		bar.add_child(tab)
	_title = StoryUI.label("", 19, StoryUI.BEIGE)
	add_child(_title)
	_entries = StoryUI.scroll_column(self)
	for enemy in configuration.enemies():
		_add_enemy(enemy)
	_select_slot(slot)

func _add_enemy(enemy: BattleEnemyDefinition) -> void:
	var id := enemy.enemy_id
	var panel := StoryUI.panel(_entries)
	var row := StoryUI.row(panel, 8)
	var copy := StoryUI.column(row, 3)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_stretch_ratio = 1.6
	copy.add_child(StoryUI.label(enemy.display_name, 18))
	copy.add_child(StoryUI.label("%d pts each" % enemy.chaos_points, 16, StoryUI.BEIGE))
	var slider := HSlider.new()
	slider.name = "Quantity_" + String(id).replace(".", "_")
	var touch := StoryUI.android_touch_minimum(self)
	slider.custom_minimum_size = Vector2(90, touch.y)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.tooltip_text = enemy.display_name
	slider.step = 1.0
	slider.value_changed.connect(_set_count.bind(id))
	row.add_child(slider)
	_sliders[id] = slider
	_down[id] = _step_button(row, "−", "Decrease_", id, -1)
	var quantity_label := StoryUI.label("", 19, StoryUI.AMBER)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_label.custom_minimum_size.x = 32
	quantity_label.name = "Count_" + String(id).replace(".", "_")
	row.add_child(quantity_label)
	_quantities[id] = quantity_label
	_up[id] = _step_button(row, "+", "Increase_", id, 1)

func _step_button(row: HBoxContainer, text: String, prefix: String, id: StringName, by: int) -> Button:
	var button := StoryUI.action(text)
	button.name = prefix + String(id).replace(".", "_")
	button.pressed.connect(func() -> void: _set_count(configuration.quantity(slot, id) + by, id))
	row.add_child(button)
	return button

func _select_slot(index: int) -> void:
	slot = index
	_tabs[slot].set_pressed_no_signal(true)
	(_entries.get_parent() as ScrollContainer).scroll_vertical = 0
	_refresh()

func _set_count(requested: float, id: StringName) -> void:
	var before := configuration.quantity(slot, id)
	var count := configuration.set_quantity(slot, id, roundi(requested))
	_refresh()
	if before != count:
		changed.emit()

func _refresh() -> void:
	for index in _tabs.size():
		_tabs[index].text = "Wave %d\n%d / %d" % [index + 1, configuration.wave_size(index), ChaosConfiguration.ENEMIES_PER_WAVE]
	var used := configuration.wave_size(slot)
	_title.text = "Empty slot · skipped" if used == 0 else "%s enemy points" % StoryUI.funds(configuration.wave_points(slot))
	if used == ChaosConfiguration.ENEMIES_PER_WAVE:
		_title.text += " · Wave full"
	for id: StringName in _sliders:
		var count := configuration.quantity(slot, id)
		var cap := configuration.capacity_for(slot, id)
		_sliders[id].set_block_signals(true)
		_sliders[id].max_value = cap
		_sliders[id].set_value_no_signal(count)
		_sliders[id].set_block_signals(false)
		_sliders[id].editable = cap > 0
		_quantities[id].text = str(count)
		_down[id].disabled = count == 0
		_up[id].disabled = count == cap
