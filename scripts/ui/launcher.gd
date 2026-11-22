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
@export var first_contact_trial := false
@export var campaign_save_path := CampaignProgress.DEFAULT_PATH

@onready var _content: Control = %ScreenContent
var _screen: Control
var _route: StringName
var _progress: FirstContactProgress
var _campaign: CampaignContent
var _campaign_progress: CampaignProgress
var _draft: OperationPlan
var _finance_elapsed := 0.0
var _focused := true
var _suspended := false
var _access_return: Callable
# Filled by HQ progression when that subsystem is present. Tests inject a researched effect.
var unlocked_buff_ids: Array[StringName] = []

func _ready() -> void:
	get_tree().quit_on_go_back = false
	get_viewport().size_changed.connect(_resize_controls)
	if first_contact_trial:
		_progress = FirstContactProgress.new(save_path)
	else:
		_campaign = CampaignContent.new()
		_campaign_progress = CampaignProgress.new(campaign_save_path)
		if _profile().leader_name.is_empty():
			var legacy: String = FirstContactProgress.new(save_path).snapshot().leader_name
			if not legacy.is_empty():
				_campaign_progress.set_leader_name(legacy)
	if _profile().leader_name.is_empty():
		show_naming()
		return
	if _campaign != null:
		var pending := _campaign.operation(StringName(_profile().pending_attempt))
		if pending != null and _campaign_progress.access_error(pending).is_empty():
			_show_campaign_plan(pending)
			return
	show_menu()

func _profile() -> Dictionary:
	return _progress.snapshot() if first_contact_trial else _campaign_progress.snapshot()

func _process(delta: float) -> void:
	if _campaign_progress == null or not _focused or _suspended:
		return
	if _screen is BattleScene and (_screen.battle == null or not _screen.battle.clock.is_running()):
		return
	_campaign_progress.advance_finance(delta)
	_finance_elapsed += delta
	if _finance_elapsed >= 10.0:
		_finance_elapsed = 0.0
		_campaign_progress.flush_finance()

func _exit_tree() -> void:
	if _campaign_progress != null:
		_campaign_progress.flush_finance()

func show_naming() -> void:
	var page := NAMING.instantiate()
	page.name_submitted.connect(func(value: String) -> void:
		var saved := _progress.set_leader_name(value) if first_contact_trial else _campaign_progress.set_leader_name(value)
		if saved:
			show_menu()
		elif not value.strip_edges().is_empty():
			page.feedback.text = "Could not save the Leader name. Check local storage."
	)
	_present(page, &"name")

func show_menu() -> void:
	var page: Control = MAIN_MENU.instantiate()
	var profile := _profile()
	page.get_node("%ProfileSummary").text = "Leader %s   ·   %d Funds" % [profile.leader_name, profile.funds]
	page.get_node("%OpenSample").pressed.connect(show_sample)
	page.get_node("%OpenCampaign").pressed.connect(show_story)
	if not first_contact_trial:
		page.get_node("Modes/Headquarters/Office/Status").text = "Placeholder HQ art"
		var access := StoryUI.action("Campaign access")
		access.pressed.connect(func() -> void: _show_access(show_menu))
		page.get_node("Modes/Headquarters/Office").add_child(access)
		page.get_node("Modes/Operations/Chaos/Description/Status").text = "Mode locked"
	_present(page, &"menu")
	page.get_node("%OpenCampaign").grab_focus()

func show_story() -> void:
	if not first_contact_trial:
		if not _campaign_progress.abandon_attempt() and _route == &"plan":
			_screen.show_error("Could not close the saved attempt. Check local storage.")
			return
		var story := CampaignStoryPage.new()
		story.content = _campaign
		story.progress = _campaign_progress
		story.back_requested.connect(show_menu)
		story.access_requested.connect(func() -> void: _show_access(show_story))
		story.operation_requested.connect(_show_campaign_plan)
		_present(story, &"story")
		return
	_progress = FirstContactProgress.new(save_path)
	var page := STORY_PAGE.instantiate()
	page.index = STORY_INDEX
	page.operation = FIRST_CONTACT
	page.progress = _progress.snapshot()
	page.back_requested.connect(show_menu)
	page.operation_requested.connect(show_planning)
	_present(page, &"story")

func _show_campaign_plan(operation: StoryOperation) -> void:
	if not _campaign_progress.access_error(operation).is_empty():
		show_story()
		return
	var profile := _profile()
	if _draft == null or _draft.operation != operation:
		_draft = OperationPlan.new(operation, unlocked_buff_ids)
		_draft.configure_campaign(profile)
	elif _draft.facility_limit == 0 and profile.mechanical:
		var selection := _draft.selected_ids.duplicate()
		selection.append(&"facility.logistics_post")
		_draft.configure_campaign(profile, selection)
	var page := PLANNING.instantiate()
	page.plan = _draft
	page.funds = profile.funds
	page.back_requested.connect(show_story)
	page.access_requested.connect(func() -> void: _show_access(_show_campaign_plan.bind(operation)))
	page.start_requested.connect(_start_campaign)
	_present(page, &"plan")

func _show_access(back: Callable) -> void:
	_access_return = back
	var page := CampaignAccessPage.new()
	page.progress = _campaign_progress
	page.back_requested.connect(_access_return)
	_present(page, &"access")

func _start_campaign() -> void:
	if _draft == null or not _draft.can_start():
		return
	if not _campaign_progress.begin_attempt(_draft.operation):
		_screen.show_error("Could not start the operation. Check access and local storage.")
		return
	var node := SAMPLE_BATTLE.instantiate()
	node.set_script(CampaignBattle)
	var page := node as CampaignBattle
	page.progress = _campaign_progress
	page.content = _campaign
	page.campaign = true
	page.stage = _draft.operation.stage
	page.operation_plan = _draft
	page.get_node("%DeploymentController").roster = _draft.operation.roster
	page.abandon_requested.connect(func() -> void:
		var saved := _campaign_progress.abandon_attempt()
		_show_campaign_plan(_draft.operation)
		if not saved:
			_screen.show_error("Could not close the saved attempt. Check local storage.")
	)
	page.operation_finished.connect(_show_results, CONNECT_DEFERRED)
	_present(page, &"battle")

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
	var page := RESULTS.instantiate()
	page.report = report
	if first_contact_trial:
		_progress = FirstContactProgress.new(save_path)
		page.planning_requested.connect(show_planning)
	else:
		page.planning_requested.connect(_show_campaign_plan.bind(_draft.operation))
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
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_suspended = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
		else:
			_suspended = true
		if _campaign_progress != null:
			_campaign_progress.flush_finance()

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
		&"access":
			_access_return.call()
		&"story", &"sample":
			show_menu()
