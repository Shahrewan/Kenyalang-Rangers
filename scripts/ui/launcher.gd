extends Control

const NAMING := preload("res://scenes/menus/leader_naming.tscn")
const MAIN_MENU := preload("res://scenes/menus/main_menu.tscn")
const STORY_PAGE := preload("res://scenes/menus/story_page.tscn")
const PLANNING := preload("res://scenes/menus/planning_page.tscn")
const RESULTS := preload("res://scenes/menus/operation_results.tscn")
const FIRST_CONTACT := preload("res://data/stages/c09_first_contact_operation.tres")
const STORY_INDEX := preload("res://data/stages/story_index.tres")
const SAMPLE_BATTLE := preload("res://scenes/battle/sample_battle.tscn")

@export var save_path := FirstContactProgress.DEFAULT_PATH

@onready var _content: Control = %ScreenContent
var _screen: Control
var _route: StringName
var _progress: FirstContactProgress
var _draft: OperationPlan
# Filled by HQ progression when that subsystem is present. Tests inject a researched effect.
var unlocked_buff_ids: Array[StringName] = []

func _ready() -> void:
	get_tree().quit_on_go_back = false
	get_viewport().size_changed.connect(_resize_controls)
	_progress = FirstContactProgress.new(save_path)
	if _progress.snapshot().leader_name.is_empty():
		show_naming()
	else:
		show_menu()

func show_naming() -> void:
	var page := NAMING.instantiate()
	page.name_submitted.connect(func(value: String) -> void:
		if _progress.set_leader_name(value):
			show_menu()
		elif not value.strip_edges().is_empty():
			page.feedback.text = "Could not save the Leader name. Check local storage."
	)
	_present(page, &"name")

func show_menu() -> void:
	var page: Control = MAIN_MENU.instantiate()
	var profile := _progress.snapshot()
	page.get_node("%ProfileSummary").text = "Leader %s   ·   %d Funds" % [profile.leader_name, profile.funds]
	page.get_node("%OpenSample").pressed.connect(show_sample)
	page.get_node("%OpenCampaign").pressed.connect(show_story)
	_present(page, &"menu")
	page.get_node("%OpenCampaign").grab_focus()

func show_story() -> void:
	_progress = FirstContactProgress.new(save_path)
	var page := STORY_PAGE.instantiate()
	page.index = STORY_INDEX
	page.operation = FIRST_CONTACT
	page.progress = _progress.snapshot()
	page.back_requested.connect(show_menu)
	page.operation_requested.connect(show_planning)
	_present(page, &"story")

func show_planning() -> void:
	_progress = FirstContactProgress.new(save_path)
	if _draft == null:
		_draft = OperationPlan.new(FIRST_CONTACT, unlocked_buff_ids)
	var page := PLANNING.instantiate()
	page.plan = _draft
	page.funds = _progress.snapshot().funds
	page.back_requested.connect(show_story)
	page.start_requested.connect(show_first_contact)
	_present(page, &"plan")

func show_sample() -> void:
	var page := SAMPLE_BATTLE.instantiate() as BattleScene
	var back: Button = page.get_node("%BackToMenu")
	back.pressed.connect(show_menu)
	_present(page, &"sample")
	back.grab_focus()

func show_first_contact() -> void:
	if _draft == null or not _draft.can_start():
		return
	var page := SAMPLE_BATTLE.instantiate() as BattleScene
	page.campaign = true
	page.operation_plan = _draft
	page.stage = _draft.operation.stage
	page.save_path = save_path
	page.abandon_requested.connect(show_planning)
	page.operation_finished.connect(_show_results, CONNECT_DEFERRED)
	_present(page, &"battle")

func _show_results(report: Dictionary) -> void:
	if _route != &"battle":
		return
	_progress = FirstContactProgress.new(save_path)
	var page := RESULTS.instantiate()
	page.report = report
	page.planning_requested.connect(show_planning)
	page.story_requested.connect(show_story)
	_present(page, &"results")

func _present(page: Control, route: StringName) -> void:
	if is_instance_valid(_screen):
		_content.remove_child(_screen)
		_screen.queue_free()
	_route = route
	_screen = page
	_content.add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resize_controls()

func _resize_controls() -> void:
	if is_instance_valid(_screen):
		StoryUI.size_buttons(_screen)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		_go_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()

func _go_back() -> void:
	match _route:
		&"battle":
			_screen.request_back()
		&"plan", &"results":
			show_story()
		&"story", &"sample":
			show_menu()
