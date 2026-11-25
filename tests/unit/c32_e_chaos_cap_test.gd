extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const PATROL := &"ranger.patrolman"
const POST := &"facility.logistics_post"
const RELAY := &"facility.skill_relay_station"
const DEBUFFS: Array[StringName] = [&"D02", &"D03", &"D05", &"D07", &"D08", &"D12", &"D13", &"D15"]

var _path := "user://c32-e-cap-%d.json" % OS.get_process_id()
var _checks := 0
var _failures := 0
var _output := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(960, 540)
	if args.size() == 3 and DisplayServer.get_name() != "headless":
		_output = args[0]
		var size := args[1].split("x")
		root.size = Vector2i(size[0].to_int(), size[1].to_int())
		DirAccess.make_dir_recursive_absolute(_output)

	var fixture := CampaignSave.fresh()
	fixture.leader_name = "Rimba"
	fixture.rooms["room.mechanical"] = 1
	fixture.rooms["room.r_d_combat"] = 2
	_check(ProfileFile.replace(_path, fixture, false), "Prepare a fresh wallet with built Mechanical and eligible research")
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	if not _output.is_empty():
		app.presentation.values.text = int(args[2])
		app._restyle()
	app.show_chaos()
	_press(app, "Route_T01")
	var configuration: ChaosConfiguration = app._chaos_configuration
	configuration.set_quantity(0, &"E01", 2)
	configuration.set_quantity(1, &"E01", 1)
	_press(app, "ConfigureChaos")
	var plan: OperationPlan = app._chaos_plan
	plan.configure_campaign(app._campaign_progress, [PATROL, POST])
	app._render_chaos_composer()
	_press(app, "OpenModifiers")
	_press(app, "ShowDebuffs")
	for debuff in DEBUFFS:
		var button := _button(app, "Modifier_" + String(debuff))
		_check(not button.disabled, String(debuff) + " is eligible and active in the test configuration")
		button.button_pressed = true
	_check("130 Medal Score" in _label(app, "ModifierSummary") and "2,600 Funds" in _label(app, "ModifierSummary")
		and "+200 of +1,100 (capped)" in _label(app, "ModifierSummary"), "Modifier sheet previews the capped score and conditional payout")
	await _capture("modifier-cap")
	_press(app, "ApplyModifiers")
	_check(_label(app, "MedalScore") == "130" and "2,600 Funds" in _label(app, "ChaosPayout")
		and "Unranked" in _label(app, "ProjectedTrophy") and "+200 of +1,100 (capped)" in _label(app, "ScoreBreakdown")
		and "1 Ranger / 0 Facility slots  −100" in _label(app, "ScoreBreakdown"),
		"Composer shows the cap and only the one effective Ranger slot under D05")
	await _capture("chaos-cap-preview")

	_press(app, "OpenModifiers")
	var buff := _button(app, "Modifier_B05")
	buff.button_pressed = true
	_check("30 Medal Score" in _label(app, "ModifierSummary") and "600 Funds" in _label(app, "ModifierSummary"),
		"The full negative buff credit applies after the positive cap")
	_press(app, "BackFromModifiers")
	_check(_label(app, "MedalScore") == "130", "Cancel restores the uncoupled buff choice and capped score")
	(app._screen as ChaosComposer).configuration.set_quantity(0, &"E01", 21)
	(app._screen as ChaosComposer)._update_waves()
	_check(_label(app, "MedalScore") == "340" and "+220 of +1,100" in _label(app, "ScoreBreakdown"),
		"Wave edits raise the cap above its 200-point floor when configured enemy points grow")
	configuration.set_quantity(0, &"E01", 2)
	(app._screen as ChaosComposer)._update_waves()
	_press(app, "StartChaos")
	var field := app._screen as ChaosBattle
	field.set_physics_process(false)
	var sim := field.battle
	var state := sim.deployment
	var patrol: DeploymentSpec
	for spec: DeploymentSpec in plan.deployment_entries():
		if spec.id == PATROL:
			patrol = spec
	_check(field.run.score.points() == 130 and state.tokens == 120 and patrol != null
		and state.deploy(patrol, Vector2i(2, 1), -1).is_empty(), "Live battle receives the identical score and legal Patrolman placement")
	for frame in 10000:
		if sim.clock.stopped:
			break
		sim.clock.advance_frame()
	field._refresh()
	await process_frame
	var progress: CampaignProgress = app._campaign_progress
	_check(sim.configured_defeated == 3 and sim.escaped == 0 and progress.funds() == 12600 and progress.chaos_personal_best() == 130
		and not progress.owns(RELAY) and progress.snapshot().chaos.earned_thresholds.is_empty(),
		"Actual combat clears all three enemies and settles 2,600 without a tier unlock")
	_check(app._screen is ChaosResultsPage and _label(app, "ChaosCreditedFunds") == "2,600 Funds credited"
		and app._screen.find_children("*", "Label", true, false).any(func(label: Label) -> bool:
			return "+200 of +1,100 (capped)" in label.text),
		"Receipt shows the same effective score and payout")
	await _capture("chaos-cap-receipt")
	app.free()
	var cold := CampaignProgress.new(_path)
	_check(cold.funds() == 12600 and cold.chaos_personal_best() == 130 and not cold.owns(RELAY)
		and cold.pending_chaos_configuration().is_empty(), "Cold reload retains the capped record and payout")
	for suffix in ["", ".bak", ".tmp", ".bak.tmp", ".settings"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("C32-E Chaos cap: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _button(app: Control, id: String) -> BaseButton:
	return app._screen.find_child(id, true, false)

func _press(app: Control, id: String) -> void:
	_button(app, id).pressed.emit()

func _label(app: Control, id: String) -> String:
	return app._screen.find_child(id, true, false).text

func _capture(name: String) -> void:
	if _output.is_empty():
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == root.size and image.save_png(_output.path_join(name + ".png")) == OK,
		name + " rendered at native size")

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", label)
