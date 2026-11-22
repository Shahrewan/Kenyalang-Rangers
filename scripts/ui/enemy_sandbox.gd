extends Control

const BATTLE := preload("res://scenes/battle/sample_battle.tscn")

@export var stage_template: BattleStage
@export var trial_roster: DeploymentRoster
@export var standard_catalog: EnemyCatalog
@export var boss_catalog: EnemyCatalog
@export var trial_tokens: int

var _entries: Array[BattleEnemyDefinition]
var _selection := 0
var _page: Control

func _ready() -> void:
	get_tree().quit_on_go_back = false
	_entries = standard_catalog.entries.duplicate()
	_entries.append_array(boss_catalog.entries)
	get_viewport().size_changed.connect(_size_controls)
	_show_picker()

func _show_picker() -> void:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	var exit := StoryUI.header(page, "Enemy sandbox", get_tree().quit)
	exit.text = "Exit"
	var body := StoryUI.row(page, 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var choices := StoryUI.panel(body, true)
	choices.add_child(StoryUI.label("Encounter", 24, StoryUI.INK))
	var selector := OptionButton.new()
	selector.name = "EncounterChoice"
	selector.custom_minimum_size = StoryUI.TOUCH_MINIMUM
	selector.add_item("Standard roster")
	for entry in _entries:
		var boss := entry as BossSpec
		var prefix := String(boss.operation_id) if boss != null else String(entry.enemy_id)
		selector.add_item("%s · %s" % [prefix, entry.display_name])
	selector.select(_selection)
	selector.fit_to_longest_item = false
	choices.add_child(selector)
	var detail := StoryUI.panel(body)
	var title := StoryUI.label("", 30)
	var stats := StoryUI.label("", 20, StoryUI.AMBER)
	var description := StoryUI.label("", 20)
	detail.add_child(title)
	detail.add_child(stats)
	detail.add_child(description)
	_update_details(title, stats, description)
	selector.item_selected.connect(func(index: int) -> void:
		_selection = index
		_update_details(title, stats, description)
	)
	var controls := StoryUI.row(page)
	controls.alignment = BoxContainer.ALIGNMENT_END
	var start := StoryUI.action("Start encounter", true)
	start.name = "StartEncounter"
	start.pressed.connect(_play)
	controls.add_child(start)
	_present(page)
	var dp := StoryUI.android_touch_minimum(selector).y
	selector.get_popup().add_theme_constant_override("v_separation", maxi(14, ceili(dp) - 24))

func _update_details(title: Label, stats: Label, description: Label) -> void:
	if _selection == 0:
		title.text = "Standard roster"
		stats.text = "%d enemies across %d waves" % [standard_catalog.entries.size(), stage_template.waves.size()]
		description.text = "Try the full lineup or choose an individual enemy to repeat its encounter."
		return
	var entry := _entries[_selection - 1]
	title.text = entry.display_name
	stats.text = WaveIntel.enemy_details(entry)
	description.text = entry.counterplay
	if entry is BossSpec:
		description.text += "\n\nUse Practice hit to reach each authored HP threshold."

func _play() -> void:
	var stage := stage_template.duplicate() as BattleStage
	var selected: BattleEnemyDefinition
	if _selection > 0:
		selected = _entries[_selection - 1]
		var group := BattleSpawnGroup.new()
		group.enemy = selected
		group.count = 1
		var wave := BattleWave.new()
		wave.groups = [group]
		stage.waves = [wave]
		if selected.heat_per_second <= 0.0:
			stage.heat_capacity = 0.0
			stage.heat_integrity_loss = 0
		if selected is BossSpec and selected.capturable:
			stage.capture_boss_id = selected.enemy_id
	var field := BATTLE.instantiate() as BattleScene
	field.stage = stage
	field.sandbox = true
	field.sandbox_title = selected.display_name if selected != null else "Standard roster"
	field.sandbox_legend = "Placeholder art · A: Aerial · T: Technological · ?: Hidden"
	field.sandbox_return_label = "Roster"
	field.sandbox_practice_hits = selected is BossSpec
	field.sandbox_exit_requested.connect(_show_picker)
	var controller := field.get_node("%DeploymentController")
	controller.roster = trial_roster
	controller.preview_budget = trial_tokens
	controller.records_enhancements.assign([&"records_chapter.scout_sniper"])
	_present(field)

func _present(page: Control) -> void:
	if is_instance_valid(_page):
		%Content.remove_child(_page)
		_page.queue_free()
	_page = page
	%Content.add_child(_page)
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_size_controls()

func _size_controls() -> void:
	if is_instance_valid(_page):
		StoryUI.size_buttons(_page)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		_go_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()

func _go_back() -> void:
	var field := _page as BattleScene
	if field == null:
		get_tree().quit()
	elif field.battle.clock.dialogue_open or field.battle.clock.paused:
		field.request_back()
	else:
		_show_picker()
