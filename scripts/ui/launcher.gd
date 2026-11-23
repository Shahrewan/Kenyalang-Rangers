extends Control

const NAMING := preload("res://scenes/menus/leader_naming.tscn")
const MAIN_MENU := preload("res://scenes/menus/main_menu.tscn")
const STORY_PAGE := preload("res://scenes/menus/story_page.tscn")
const PLANNING := preload("res://scenes/menus/planning_page.tscn")
const RESULTS := preload("res://scenes/menus/operation_results.tscn")
const FIRST_CONTACT := preload("res://data/stages/c09_first_contact_operation.tres")
const STORY_INDEX := preload("res://data/stages/story_index.tres")
const SAMPLE_BATTLE := preload("res://scenes/battle/sample_battle.tscn")
const MODIFIER_TRIAL := preload("res://data/stages/c16_modifier_trial.tres")

@export var save_path := FirstContactProgress.DEFAULT_PATH
@export var first_contact_trial := false
@export var campaign_save_path := CampaignProgress.DEFAULT_PATH

@onready var _content: Control = %ScreenContent
var _screen: Control
var _route: StringName
var _progress: FirstContactProgress
var _campaign: CampaignContent
var _campaign_progress: CampaignProgress
var education_catalog: EducationCatalog
var garden_time: Callable = Time.get_unix_time_from_system
var _draft: OperationPlan
var _trial_plan: OperationPlan
var _chaos_configuration := ChaosConfiguration.new()
var _chaos_plan: OperationPlan
var _chaos_origin: Callable
var _finance_elapsed := 0.0
var presentation := PresentationAudio.new()
var _guide: FieldGuide
var _guide_origin: Control
var _focused := true
var _suspended := false
var _headquarters_return: Callable
var _return_action: Callable
# The isolated First Contact fixture can be given a researched effect.
var unlocked_buff_ids: Array[StringName] = []

func _ready() -> void:
	presentation.path = campaign_save_path + ".settings"
	add_child(presentation)
	get_tree().node_added.connect(_control_added)
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
		var chaos := _campaign_progress.pending_chaos_configuration()
		if not chaos.is_empty():
			_reopen_chaos(chaos)
			return
		var pending := _campaign.operation(StringName(_profile().pending_attempt))
		if pending != null and _campaign_progress.access_error(pending).is_empty():
			_show_campaign_plan(pending)
			return
	show_menu()

func _profile() -> Dictionary:
	return _progress.snapshot() if first_contact_trial else _campaign_progress.snapshot()

func _process(delta: float) -> void:
	if _screen is BattleScene and _screen.battle != null:
		presentation.hold(not _screen.battle.clock.is_running())
	elif _screen is RecordsQuizPage:
		presentation.hold(_screen.quiz.paused)
	if _campaign_progress == null or not _focused or _suspended or _route in [&"name", &"recovery"]:
		return
	if _screen is BattleScene and (_screen.battle == null or not _screen.battle.clock.is_running()):
		return
	if _screen is RecordsQuizPage and _screen.quiz.paused:
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
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.get_node("Footer").add_child(spacer)
		var faq := StoryUI.action("FAQ")
		faq.name = "OpenFAQ"
		page.get_node("Footer").add_child(faq)
		faq.pressed.connect(_open_guide.bind(""))
		var garden: Button = page.get_node("%Garden")
		garden.disabled = false
		garden.text = "Reforestation"
		garden.pressed.connect(func() -> void: _show_garden(show_menu))
		var chaos_card := page.get_node("Modes/Operations/Chaos/Description")
		chaos_card.get_node("Status").hide()
		var chaos := StoryUI.action("Choose route", true)
		chaos.name = "OpenChaos"
		chaos.pressed.connect(show_chaos)
		chaos_card.add_child(chaos)
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
	if _draft == null or _draft.operation != operation:
		_draft = OperationPlan.new(operation, [])
		_draft.configure_campaign(_campaign_progress)
	else:
		_refresh_hq_choices(_draft)
	_render_campaign_plan()

func _render_campaign_plan() -> void:
	var operation := _draft.operation
	var access := func() -> void: _open_headquarters(_show_campaign_plan.bind(operation))
	_present_playable_plan(_draft, show_story, access, _start_campaign, _render_campaign_plan)

func _show_trial_plan() -> void:
	if _trial_plan == null:
		_trial_plan = _new_chaos_plan(MODIFIER_TRIAL, "Rainforest Chaos · Modifier trial")
	else:
		_refresh_hq_choices(_trial_plan)
	_render_trial_plan()

func _new_chaos_plan(stage: BattleStage, title: String, selection: Variant = null) -> OperationPlan:
	var operation := StoryOperation.new()
	operation.campaign_spec = true
	operation.title = title
	operation.stage = stage
	operation.roster = _campaign.roster
	operation.opening_rules = LogisticsRules.new()
	var plan := OperationPlan.new(operation, [], true)
	plan.configure_campaign(_campaign_progress, selection)
	return plan

func _refresh_hq_choices(plan: OperationPlan) -> void:
	var selection := plan.selected_ids.duplicate()
	if plan.facility_limit == 0 and _campaign_progress.room_level(HeadquartersCatalog.MECHANICAL) > 0:
		selection.append(&"facility.logistics_post")
	plan.configure_campaign(_campaign_progress, selection)

func _render_trial_plan() -> void:
	var access := func() -> void: _open_headquarters(_show_trial_plan)
	var back := _show_chaos_routes if _chaos_origin.is_valid() else show_menu
	_present_playable_plan(_trial_plan, back, access, _start_trial, _render_trial_plan)

func _present_playable_plan(plan: OperationPlan, back: Callable, access: Callable, start: Callable, return_to_plan: Callable) -> void:
	var page := PLANNING.instantiate()
	page.plan = plan
	page.funds = _campaign_progress.funds()
	page.back_requested.connect(back)
	page.access_requested.connect(access)
	page.start_requested.connect(start)
	page.modifiers_requested.connect(_show_modifier_picker.bind(plan, return_to_plan))
	_present(page, &"plan", back)

func _show_modifier_picker(plan: OperationPlan, back: Callable) -> void:
	var page := ModifierPicker.new()
	page.plan = plan
	page.back_requested.connect(back)
	_present(page, &"modifiers", back)

func _start_trial() -> void:
	if _trial_plan == null or not _trial_plan.can_start():
		return
	var page := SAMPLE_BATTLE.instantiate() as BattleScene
	page.operation_plan = _trial_plan
	page.stage = _trial_plan.resolved().stage
	page.sandbox = true
	page.sandbox_title = "Modifier trial"
	page.sandbox_legend = "Placeholder board art"
	page.sandbox_return_label = "Back to plan"
	var controller := page.get_node("%DeploymentController")
	controller.roster = _trial_plan.operation.roster
	controller.records_enhancements = _campaign_progress.records_enhancements()
	page.sandbox_exit_requested.connect(_render_trial_plan)
	page.abandon_requested.connect(_render_trial_plan)
	_present(page, &"sample", _render_trial_plan)

func show_chaos(return_to := Callable()) -> void:
	_chaos_origin = return_to if return_to.is_valid() else show_menu
	_show_chaos_routes()

func _show_chaos_routes() -> void:
	var page := ChaosRoutePage.new()
	page.configuration = _chaos_configuration
	page.progress = _campaign_progress
	page.back_requested.connect(_chaos_origin)
	page.configure_requested.connect(_configure_chaos)
	page.trial_requested.connect(_show_trial_plan)
	_present(page, &"chaos_routes", _chaos_origin)

func _configure_chaos() -> void:
	if _chaos_plan == null:
		_chaos_plan = _new_chaos_plan(_chaos_configuration.build_stage(), "Rainforest Chaos")
	else:
		_refresh_hq_choices(_chaos_plan)
		_chaos_plan.update_stage(_chaos_configuration.build_stage())
	_render_chaos_composer()

func _reopen_chaos(saved: Dictionary) -> void:
	_chaos_origin = show_menu
	_chaos_configuration = ChaosConfiguration.from_data(saved)
	var selection: Array[StringName] = []
	selection.assign(saved.loadout.map(func(id: String) -> StringName: return StringName(id)))
	_chaos_plan = _new_chaos_plan(_chaos_configuration.build_stage(), "Rainforest Chaos", selection)
	var modifiers: Array[StringName] = []
	modifiers.assign(saved.modifiers.map(func(id: String) -> StringName: return StringName(id)))
	_chaos_plan.restore_modifier_selection(modifiers)
	_render_chaos_composer()
	_screen.show_error("Challenge interrupted. Review the configuration and start a fresh attempt.")

func _render_chaos_composer(show_loadout := false, slot := 0) -> void:
	var page := ChaosComposer.new()
	page.configuration = _chaos_configuration
	page.progress = _campaign_progress
	page.plan = _chaos_plan
	page.show_loadout = show_loadout
	page.initial_slot = slot
	page.back_requested.connect(_leave_chaos_composer)
	page.modifiers_requested.connect(func() -> void:
		_open_chaos_modifiers(_render_chaos_composer.bind(page.show_loadout, page.wave_editor.slot))
	)
	page.headquarters_requested.connect(func() -> void:
		var wave := page.wave_editor.slot
		var original_back := _headquarters_return
		_open_headquarters(func() -> void:
			_headquarters_return = original_back
			_refresh_hq_choices(_chaos_plan)
			_render_chaos_composer(true, wave)
		)
	)
	page.start_requested.connect(func() -> void:
		_start_chaos(_render_chaos_composer.bind(page.show_loadout, page.wave_editor.slot))
	)
	_present(page, &"chaos_composer", _leave_chaos_composer)

func _leave_chaos_composer() -> void:
	if _campaign_progress.close_chaos_configuration():
		_show_chaos_routes()
	else:
		_screen.show_error("Could not close the saved configuration. Check local storage.")

func _open_chaos_modifiers(back: Callable) -> void:
	var before := _chaos_plan.modifier_selection()
	var cancel := func() -> void:
		_chaos_plan.restore_modifier_selection(before)
		back.call()
	var page := ModifierPicker.new()
	page.plan = _chaos_plan
	page.confirm_changes = true
	page.back_requested.connect(cancel)
	page.apply_requested.connect(back)
	_present(page, &"modifiers", cancel)

func _start_chaos(review: Callable) -> void:
	var resolved := _chaos_plan.resolved()
	var run := _campaign_progress.begin_chaos(_chaos_configuration, resolved, _chaos_plan.selected_ids, _chaos_plan.modifier_selection())
	if run == null:
		_screen.show_error("Could not start the challenge. Check the configuration and local profile.")
		return
	var node := SAMPLE_BATTLE.instantiate()
	node.set_script(ChaosBattle)
	var page := node as ChaosBattle
	page.run = run
	page.operation_plan = _chaos_plan
	page.stage = resolved.stage
	var controller := page.get_node("%DeploymentController")
	controller.roster = _chaos_plan.operation.roster
	controller.records_enhancements = _campaign_progress.records_enhancements()
	page.abandon_requested.connect(func() -> void:
		var closed := _campaign_progress.abandon_chaos(run)
		review.call()
		if not closed:
			_screen.show_error("Could not close the interrupted configuration. Check local storage.")
	)
	page.completed.connect(func() -> void:
		if _screen == page:
			_render_chaos_result(run, review)
	, CONNECT_DEFERRED)
	_present(page, &"chaos_battle")

func _render_chaos_result(run: ChaosRun, review: Callable) -> void:
	var page := ChaosResultsPage.new()
	page.run = run
	page.progress = _campaign_progress
	page.settlement = _campaign_progress.settle_chaos(run)
	page.retry_save_requested.connect(_render_chaos_result.bind(run, review))
	page.routes_requested.connect(func() -> void:
		var closed := _campaign_progress.abandon_chaos(run)
		if closed:
			_show_chaos_routes()
		else:
			review.call()
			_screen.show_error("Could not close the saved configuration. Check local storage.")
	)
	page.review_requested.connect(func() -> void:
		_refresh_hq_choices(_chaos_plan)
		review.call()
	)
	_present(page, &"chaos_results", page.request_back)
	presentation.cue("victory" if run.qualifies() else "defeat")

func _open_headquarters(back: Callable) -> void:
	_headquarters_return = back
	_show_headquarters()

func _show_headquarters() -> void:
	var page := HeadquartersOverview.new()
	page.progress = _campaign_progress
	page.back_requested.connect(_headquarters_return)
	page.room_requested.connect(_show_hq_room)
	page.chaos_requested.connect(show_chaos.bind(_open_headquarters.bind(_headquarters_return)))
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
			_show_garden(_show_hq_room.bind(room), true)
		HeadquartersRoom.Role.OUTREACH:
			_show_outreach(room)
		HeadquartersRoom.Role.RECORDS:
			_show_records(room)

func _education() -> EducationCatalog:
	if education_catalog == null:
		education_catalog = EducationCatalog.load_installed()
	return education_catalog

func _show_outreach(room: HeadquartersRoom) -> void:
	var page := OutreachPage.new()
	page.progress = _campaign_progress
	page.catalog = _education()
	var back := _show_hq_room.bind(room)
	page.back_requested.connect(back)
	_present(page, &"outreach", back)

func _show_records(room: HeadquartersRoom) -> void:
	var page := RecordsArchivePage.new()
	page.progress = _campaign_progress
	page.catalog = _education()
	var back := _show_hq_room.bind(room)
	page.quiz_requested.connect(_show_records_quiz.bind(room))
	page.back_requested.connect(back)
	_present(page, &"records", back)

func _show_records_quiz(quiz: RecordsQuiz, room: HeadquartersRoom) -> void:
	var page := RecordsQuizPage.new()
	page.progress = _campaign_progress
	page.catalog = _education()
	page.quiz = quiz
	page.back_requested.connect(_show_records.bind(room))
	_present(page, &"quiz", page.request_back)

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

func _show_garden(back: Callable, from_ecology := false) -> void:
	var page := HeadquartersGarden.new()
	page.progress = _campaign_progress
	page.catalog = _education()
	page.read_time = garden_time
	page.back_requested.connect(back)
	page.ecology_requested.connect(func() -> void:
		if not from_ecology:
			_headquarters_return = back
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
	page.preferences = presentation
	page.text_changed.connect(_restyle)
	page.help_requested.connect(_open_guide.bind(""))
	page.back_requested.connect(back)
	page.reset_requested.connect(func() -> void:
		if _campaign_progress.reset_profile():
			_draft = null
			_trial_plan = null
			_chaos_plan = null
			_chaos_configuration = ChaosConfiguration.new()
			show_naming()
		else:
			page.show_error()
	)
	_present(page, &"settings", page.request_back)

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
	page.stage = _draft.resolved().stage
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
	page.stage = _draft.resolved().stage
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
	presentation.cue("defeat" if report.outcome == "Defeat" else "victory")

func _present(page: Control, route: StringName, back := Callable()) -> void:
	if is_instance_valid(_screen):
		_content.remove_child(_screen)
		_screen.queue_free()
	_route = route
	_return_action = back
	_screen = page
	if page.has_signal("article_requested"):
		page.connect("article_requested", _open_guide)
	if page.has_signal("sound_requested"):
		page.connect("sound_requested", presentation.cue)
	presentation.set_route(route)
	_content.add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resize_controls()

func _open_guide(fact_id: String) -> void:
	if is_instance_valid(_guide):
		return
	_guide_origin = get_viewport().gui_get_focus_owner()
	_screen.hide()
	_guide = FieldGuide.new()
	_guide.catalog = _education()
	_guide.initial_fact = fact_id
	_guide.closed.connect(_close_guide)
	_content.add_child(_guide)
	_guide.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_guide.find_children("*", "Button", true, false)[0].grab_focus()

func _close_guide() -> void:
	_content.remove_child(_guide)
	_guide.queue_free()
	_guide = null
	_screen.show()
	if is_instance_valid(_guide_origin) and _guide_origin.is_visible_in_tree():
		_guide_origin.grab_focus()

func _control_added(node: Node) -> void:
	if node is Control and is_ancestor_of(node):
		_style_control.call_deferred(weakref(node))

func _restyle() -> void:
	for control: Control in _content.find_children("*", "Control", true, false):
		_style_control(weakref(control))

func _style_control(reference: WeakRef) -> void:
	var control := reference.get_ref() as Control
	if not is_instance_valid(control) or not control.is_inside_tree():
		return
	if control is BaseButton or control is Slider:
		control.custom_minimum_size = control.custom_minimum_size.max(StoryUI.android_touch_minimum(control))
	if control is Button and not control.pressed.is_connected(_click_sound):
		control.pressed.connect(_click_sound)
	if control is Label or control is Button or control is LineEdit:
		if not control.has_meta("base_font_size"):
			control.set_meta("base_font_size", control.get_theme_font_size("font_size"))
		control.add_theme_font_size_override("font_size", roundi(float(control.get_meta("base_font_size")) * presentation.values.text / 100.0))

func _click_sound() -> void:
	if not presentation.effects.playing:
		presentation.cue("confirm")

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
		if _screen is BattleScene and _screen.battle != null and _screen.battle.clock.is_running():
			_screen.request_back()
		if _campaign_progress != null:
			_campaign_progress.flush_finance()

	if is_instance_valid(presentation) and presentation.is_node_ready() and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		presentation.background(not _focused or _suspended)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()

func _go_back() -> void:
	if is_instance_valid(_guide):
		_guide.back()
		return
	if _return_action.is_valid():
		_return_action.call()
		return
	match _route:
		&"battle", &"chaos_battle":
			_screen.request_back()
		&"plan", &"results":
			show_story()
		&"story", &"sample":
			show_menu()
