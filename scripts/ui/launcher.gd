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
var _headquarters_return: Callable
var _return_action: Callable
# The isolated First Contact fixture can be given a researched effect.
var unlocked_buff_ids: Array[StringName] = []

func _ready() -> void:
	get_tree().quit_on_go_back = false
	get_viewport().size_changed.connect(_resize_controls)
	if first_contact_trial:
		_progress = FirstContactProgress.new(save_path)
	else:
		_campaign = CampaignContent.new()
		_campaign_progress = CampaignProgress.new(campaign_save_path)
		if _campaign_progress.load_status == CampaignProgress.LoadStatus.NEW:
			var legacy: String = FirstContactProgress.new(save_path).snapshot().leader_name
			if not legacy.is_empty():
				_campaign_progress.set_leader_name(legacy)
		if not _campaign_progress.can_play() or _campaign_progress.load_status == CampaignProgress.LoadStatus.RECOVERED:
			_show_recovery()
			return
	_continue_profile()

func _continue_profile() -> void:
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
	if _campaign_progress == null or not _focused or _suspended or _route in [&"name", &"recovery"]:
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
	page.get_node("%ProfileSummary").text = "Leader %s   ·   %s Funds" % [profile.leader_name, StoryUI.funds(profile.funds)]
	page.get_node("%OpenSample").pressed.connect(show_sample)
	page.get_node("%OpenCampaign").pressed.connect(show_story)
	if not first_contact_trial:
		page.get_node("Modes/Headquarters/Office/Status").text = "Placeholder HQ art"
		var access: Button = page.get_node("%OpenHeadquarters")
		access.show()
		access.pressed.connect(func() -> void: _open_headquarters(show_menu))
		var settings: Button = page.get_node("%OpenSettings")
		settings.show()
		settings.pressed.connect(func() -> void: _show_settings(show_menu))
		var garden: Button = page.get_node("%Garden")
		garden.disabled = false
		garden.text = "Reforestation"
		garden.pressed.connect(func() -> void: _show_garden(show_menu))
		page.get_node("Modes/Operations/Chaos/Description/Status").text = "Mode locked"
		if _campaign_progress.load_status == CampaignProgress.LoadStatus.MIGRATED:
			page.add_child(StoryUI.label(_campaign_progress.load_notice, 17, StoryUI.BEIGE))
	_present(page, &"menu")
	page.get_node("%OpenCampaign" if first_contact_trial else "%OpenHeadquarters").grab_focus()

func show_story(return_to := Callable()) -> void:
	if not first_contact_trial:
		if not _campaign_progress.abandon_attempt() and _route == &"plan":
			_screen.show_error("Could not close the saved attempt. Check local storage.")
			return
		var story := CampaignStoryPage.new()
		story.content = _campaign
		story.progress = _campaign_progress
		var back := return_to if return_to.is_valid() else show_menu
		story.back_requested.connect(back)
		story.access_requested.connect(func() -> void: _open_headquarters(show_story))
		story.operation_requested.connect(_show_campaign_plan)
		_present(story, &"story", back)
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
	var selection: Variant = null
	if _draft == null or _draft.operation != operation:
		_draft = OperationPlan.new(operation, [])
	else:
		selection = _draft.selected_ids.duplicate()
		if _draft.facility_limit == 0 and _campaign_progress.room_level(HeadquartersCatalog.MECHANICAL) > 0:
			selection.append(&"facility.logistics_post")
	_draft.configure_campaign(_campaign_progress, selection)
	var page := PLANNING.instantiate()
	page.plan = _draft
	page.funds = profile.funds
	page.back_requested.connect(show_story)
	page.access_requested.connect(func() -> void: _open_headquarters(_show_campaign_plan.bind(operation)))
	page.start_requested.connect(_start_campaign)
	_present(page, &"plan")

func _open_headquarters(back: Callable) -> void:
	_headquarters_return = back
	_show_headquarters()

func _show_headquarters() -> void:
	var page := HeadquartersOverview.new()
	page.progress = _campaign_progress
	page.back_requested.connect(_headquarters_return)
	page.room_requested.connect(_show_hq_room)
	_present(page, &"headquarters", _headquarters_return)

func _show_hq_room(room: HeadquartersRoom) -> void:
	var page := HeadquartersRoomPage.new()
	page.progress = _campaign_progress
	page.definition = room
	page.back_requested.connect(_show_headquarters)
	page.activity_requested.connect(_show_room_activity)
	_present(page, &"hq_room", _show_headquarters)

func _show_room_activity(room: HeadquartersRoom) -> void:
	match room.role:
		HeadquartersRoom.Role.CONTROL:
			show_story(_show_hq_room.bind(room))
		HeadquartersRoom.Role.HR, HeadquartersRoom.Role.MECHANICAL:
			_show_roster(room)
		HeadquartersRoom.Role.ECOLOGY:
			_show_garden(_show_hq_room.bind(room))

func _show_roster(room: HeadquartersRoom) -> void:
	var page := HeadquartersRosterPage.new()
	page.rangers = room.role == HeadquartersRoom.Role.HR
	page.progress = _campaign_progress
	var back := _show_hq_room.bind(room)
	page.back_requested.connect(back)
	page.unit_requested.connect(func(spec: DeploymentSpec) -> void: _show_unit(spec, room))
	_present(page, &"hq_roster", back)

func _show_unit(spec: DeploymentSpec, room: HeadquartersRoom) -> void:
	var page := DeployableUpgradePage.new()
	page.definition = spec
	page.progress = _campaign_progress
	var back := _show_roster.bind(room)
	page.back_requested.connect(back)
	_present(page, &"hq_levels", back)

func _show_garden(back: Callable) -> void:
	var page := HeadquartersGarden.new()
	page.progress = _campaign_progress
	page.back_requested.connect(back)
	page.ecology_requested.connect(func() -> void:
		_headquarters_return = show_menu
		_show_hq_room(CampaignProgress.HEADQUARTERS.room(HeadquartersCatalog.ECOLOGY))
	)
	_present(page, &"hq_garden", back)

func _show_recovery() -> void:
	var page := VBoxContainer.new()
	var card := StoryUI.panel(page)
	card.add_child(StoryUI.label("Local save", 30))
	card.add_child(StoryUI.label(_campaign_progress.load_notice, 22, StoryUI.AMBER))
	if _campaign_progress.can_play():
		var resume := StoryUI.action("Continue", true)
		resume.pressed.connect(_continue_profile)
		card.add_child(resume)
	else:
		var settings := StoryUI.action("Open Settings", true)
		settings.name = "RecoverySettings"
		settings.pressed.connect(func() -> void: _show_settings(_show_recovery))
		card.add_child(settings)
	_present(page, &"recovery")

func _show_settings(back: Callable) -> void:
	var page := ProfileSettingsPage.new()
	page.progress = _campaign_progress
	page.back_requested.connect(back)
	page.reset_requested.connect(func() -> void:
		if _campaign_progress.reset_profile():
			_draft = null
			show_naming()
		else:
			page.show_error()
	)
	_present(page, &"settings", back)

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
	var controller := page.get_node("%DeploymentController")
	controller.roster = _draft.operation.roster
	controller.records_enhancements = _campaign_progress.records_enhancements()
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

func _present(page: Control, route: StringName, back := Callable()) -> void:
	if is_instance_valid(_screen):
		_content.remove_child(_screen)
		_screen.queue_free()
	_route = route
	_return_action = back
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
	if _return_action.is_valid():
		_return_action.call()
		return
	match _route:
		&"battle":
			_screen.request_back()
		&"plan", &"results":
			show_story()
		&"story", &"sample":
			show_menu()
