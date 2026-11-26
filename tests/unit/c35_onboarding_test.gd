extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const POST := &"facility.logistics_post"
const SCOUT := &"ranger.scout_sniper"
const PATROL := &"ranger.patrolman"
const REST_SECONDS := {
	&"C1-01": [18, 0], &"C1-02": [18, 0], &"C1-03": [18, 18, 0],
	&"C1-04": [16, 16, 0], &"C1-05": [16, 16, 0],
}

var _path := "user://c35-onboarding-%d.json" % OS.get_process_id()
var _app: Control
var _checks := 0
var _failures := 0
var _captures := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var text_percent := 130
	root.size = Vector2i(960, 540)
	if args.size() == 3 and DisplayServer.get_name() != "headless":
		var dimensions := args[0].split("x")
		root.size = Vector2i(dimensions[0].to_int(), dimensions[1].to_int())
		text_percent = args[1].to_int()
		_captures = args[2]
		DirAccess.make_dir_recursive_absolute(_captures)
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	_check(ProfileFile.replace(_path, profile, false), "Use an isolated fresh profile")
	_app = LAUNCHER.instantiate()
	_app.campaign_save_path = _path
	root.add_child(_app)
	_app.set_process(false)
	_app.presentation.values.text = text_percent
	_app._restyle()
	_check_missions()
	await _first_contact()
	if _app._route == &"results":
		await _mechanical_link()
	await _headquarters()
	_app.free()
	await process_frame
	for suffix in ["", ".tmp", ".bak", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C35 player onboarding: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check_missions() -> void:
	var campaign: CampaignContent = _app._campaign
	for operation: StoryOperation in campaign.operations:
		var id := operation.stage.stage_id
		var pages: Array = OnboardingGuide.MISSIONS.get(id, [])
		var rests: Array = REST_SECONDS.get(id, [])
		if rests.is_empty():
			_check(pages.is_empty(), "%s has no Chapter 1 lesson" % id)
			continue
		_check(pages.size() >= 4, "%s has step-by-step instruction" % id)
		var actual := operation.stage.waves.map(func(wave: BattleWave) -> int: return int(wave.rest_after_seconds))
		_check(actual == rests, "%s uses the expected rest periods and zero final rest" % id)

func _first_contact() -> void:
	await _tap_named(_app._screen, "OpenCampaign")
	await _tap_named(_app._screen, "Operation_C1_01")
	var lesson := _app._screen.find_child("MissionLesson", true, false) as OnboardingGuide
	_check(lesson != null, "Story First Contact opens with its own lesson")
	if lesson == null:
		return
	_check(lesson._heading.text == "Your first three placements" and lesson._prev.disabled,
		"Lesson begins at the first action")
	await _capture("first-contact-lesson")
	await _tap(lesson._next)
	_check(lesson._body.text.contains("Face left") and lesson._body.text.contains("Deploy"),
		"Lesson explains explicit facing before battle")
	await _tap(lesson._prev)
	_check(lesson._index == 0, "Previous repeats the first action")
	await _tap_named(_app._screen, "StartOperation")
	var field := _app._screen as CampaignBattle
	_check(field != null, "Start opens the production battle")
	if field == null:
		return
	field.set_physics_process(false)
	var sim := field.battle
	sim.clock.advance_frame()
	_check(sim.clock.tick == 0 and sim.clock.dialogue_open and field._pose.text.contains("Training"),
		"Opening briefing identifies training and uses the original dialogue hold")
	await _tap(field.get_node("%Skip"))
	_check(field._board.tutorial_cells == [Vector2i(1, 0), Vector2i(2, 0)], "Skip briefing exposes both legal starter tiles")
	await _capture("starter-placement")
	var entries := {}
	for spec: DeploymentSpec in field.operation_plan.deployment_entries():
		entries[spec.id] = spec
	_check(sim.deployment.deploy(entries[POST], Vector2i(1, 0), -1).is_empty(), "Place the free Post using the real state")
	field._refresh()
	_check(field._tip.text.contains("Save") and field._board.tutorial_cells.is_empty(),
		"Coach explains why Scout cannot be placed before Tokens arrive")
	_advance(field, 1200)
	field._refresh()
	_check(field._board.tutorial_cells == [Vector2i(5, 2)], "Affordable Scout has one marked elevated tile")
	_check(sim.deployment.deploy(entries[SCOUT], Vector2i(5, 2), -1).is_empty(), "Place the Scout at its legal mark")
	_advance(field, 1800)
	field._refresh()
	_check(field._tip.text.contains("Face left") and field._board.tutorial_cells == [Vector2i(6, 3)],
		"Patrolman instruction includes the exact direction and ground tile")
	_check(sim.deployment.deploy(entries[PATROL], Vector2i(6, 3), -1).is_empty(), "Place the Patrolman with the taught facing")
	field._refresh()
	await _capture("defending-the-bend")
	field.operation_plan.show_hints = false
	field._refresh()
	_check(field._tip.text.is_empty() and field._board.tutorial_cells.is_empty() and sim.clock.is_running(),
		"Disabling coaching clears instructions and leaves the clock running")
	field.operation_plan.show_hints = true
	var first_wave_end: Array[int] = []
	var record_break := func(wave: int) -> void:
		if wave == 1:
			first_wave_end.append(wave)
	sim.wave_resolved.connect(record_break)
	while sim.clock.tick < 12000 and first_wave_end.is_empty() and not sim.clock.stopped:
		_advance(field, sim.clock.tick + 1)
	sim.wave_resolved.disconnect(record_break)
	field._refresh()
	_check(not first_wave_end.is_empty() and field._tip.text.contains("18s"), "Show the exact new break duration after Wave 1")
	field._toggle_pause()
	_check(field._tip.text.is_empty() and field._board.tutorial_cells.is_empty(), "Pause hides the coaching overlay")
	field._toggle_pause()
	var start := sim.clock.tick
	_advance(field, start + CombatClock.TICKS_PER_SECOND)
	field._refresh()
	_check(field._tip.text.contains("17s"), "Rest countdown advances on the shared combat clock")
	_advance(field, 12000)
	field._refresh()
	if sim.clock.dialogue_open:
		await _tap(field.get_node("%Skip"))
	await process_frame
	_check(_app._route == &"results" and sim.is_perfect() and sim.defeated == 14 and sim.integrity == 100
		and _app._campaign_progress.funds() == 25000, "Taught formation earns the existing First Contact perfect clear and Funds")

func _mechanical_link() -> void:
	_check(_app._screen.training_room == HeadquartersCatalog.MECHANICAL, "First Contact result points to Mechanical")
	await _tap_named(_app._screen, "OpenTrainingRoom")
	var room := _app._screen as HeadquartersRoomPage
	_check(room != null and room.definition.id == HeadquartersCatalog.MECHANICAL
		and _app._campaign_progress.funds() == 25000, "Result opens the correct room without settling a purchase")
	_app.show_story()
	await _tap_named(_app._screen, "Operation_C1_02")
	await _tap_named(_app._screen, "TutorialMechanical")
	room = _app._screen as HeadquartersRoomPage
	_check(room != null and room.definition.id == HeadquartersCatalog.MECHANICAL and _app._campaign_progress.room_level(HeadquartersCatalog.MECHANICAL) == 0,
		"Unbuilt Mechanical link is also reachable from Hold the Line")
	if room != null:
		await _tap_back(room)
		await _tap_back(_app._screen)
		_check(_app._route == &"plan" and _app._draft.operation.stage.stage_id == &"C1-02", "HQ navigation returns to the same Story plan")

func _headquarters() -> void:
	_app.show_menu()
	await _tap_named(_app._screen, "OpenHeadquarters")
	await _tap_named(_app._screen, "OpenHeadquartersTutorial")
	var guide := _app._guide as FieldGuide
	_check(guide != null, "HQ opens its tutorial from the production overview")
	if guide == null:
		return
	var tour := guide.find_children("*", "OnboardingGuide", true, false).front() as OnboardingGuide
	_check(tour != null and tour._open.text == "Open Mechanical", "Tour starts with the first useful room")
	await _capture("headquarters-tour")
	await _tap(tour._next)
	_check(tour._open.text == "Open Control Room", "Next tour step points to mission access")
	var before: int = _app._campaign_progress.funds()
	await _tap(tour._open)
	var control := _app._screen as HeadquartersRoomPage
	_check(_app._guide == null and control != null and control.definition.id == HeadquartersCatalog.CONTROL
		and _app._campaign_progress.funds() == before, "Tour opens the exact room without buying anything")

func _advance(field: CampaignBattle, target: int) -> void:
	var clock := field.battle.clock
	while clock.tick < target and not clock.stopped:
		if clock.dialogue_open:
			field.get_node("%Skip").pressed.emit()
		clock.advance_frame()

func _tap_back(parent: Node) -> void:
	for child: Node in parent.find_children("*", "Button", true, false):
		if (child as Button).text == "Back":
			await _tap(child)
			return
	_check(false, "Expected Back button")

func _tap_named(parent: Node, id: String) -> void:
	await _tap(parent.find_child(id, true, false) as BaseButton)

func _tap(button: BaseButton) -> void:
	await process_frame
	await process_frame
	if not is_instance_valid(button) or not button.is_visible_in_tree() or button.disabled:
		_check(false, "Expected an enabled button: %s" % str(button))
		return
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
			await process_frame
		parent = parent.get_parent()
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * button.get_global_rect().get_center()
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var release := event.duplicate() as InputEventScreenTouch
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await process_frame
	await process_frame

func _capture(id: String) -> void:
	if _captures.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(_captures.path_join(id + ".png")) == OK, "Capture " + id)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
