extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const FACILITIES := [
	["logistics_post", "168 HP", "200 HP", "15 Tokens per 10 s", "+4.04 Tokens"],
	["electric_pulse_turret", "314 HP", "375 HP", "18 base damage per hit"],
	["skill_relay_station", "199 HP", "238 HP", "3.6 s less skill recharge per pulse"],
	["disruption_beacon", "346 HP", "413 HP", "24% less damage from enemies in range"],
]

var _save := "user://c32-b-capture-%d.json" % OS.get_process_id()
var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3 or DisplayServer.get_name() == "headless":
		printerr("Use the native renderer and pass an output directory, width×height and text percent.")
		quit(1)
		return
	var dimensions := args[1].split("x")
	root.size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	DirAccess.make_dir_recursive_absolute(args[0])
	_seed_profile()
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _save
	root.add_child(app)
	app.set_process(false)
	app.presentation.values.text = int(args[2])
	app._restyle()
	if app._screen.get_node_or_null("%OpenHeadquarters") == null:
		printerr("Capture profile did not load the home screen.")
		quit(1)
		return
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	for fixture: Array in FACILITIES:
		app._screen.find_child("Room_mechanical", true, false).pressed.emit()
		app._screen._activity.pressed.emit()
		app._screen.find_child("Unit_" + fixture[0], true, false).pressed.emit()
		var page := app._screen as DeployableUpgradePage
		page.find_child("Milestone100", true, false).pressed.emit()
		_check(fixture[1] in page._current.text and fixture[2] in page._preview.text
			and fixture[3] in page._preview.text and (fixture.size() == 4 or fixture[4] in page._preview.text)
			and page._target_level.text == "Target level 100" and "1,200,000" in page._balance.text
			and "Cost 939,904 Funds" in page._price.text and "After purchase 260,096 Funds" in page._price.text and not page._buy.disabled,
			fixture[0] + " shows effective current and target stats, prices and balance")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		_check(image.get_size() == root.size and image.save_png(args[0].path_join(fixture[0] + ".png")) == OK,
			fixture[0] + " screenshot at requested native dimensions")
		page.back_requested.emit()
		app._screen.back_requested.emit()
		app._screen.back_requested.emit()
	app.free()
	for stem in [_save, _save + ".settings"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("C32-B native capture: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _seed_profile() -> void:
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	profile.funds = 1_200_000
	profile.rooms[String(HeadquartersCatalog.MECHANICAL)] = 2
	profile.chaos.personal_best = 1000
	profile.chaos.earned_thresholds = [ChaosScore.tier_id(1000)]
	profile.owned.append("facility.skill_relay_station")
	for operation: StoryOperation in CampaignContent.new().operations:
		if operation.stage.stage_id == &"C2-06":
			break
		profile.records[String(operation.stage.stage_id)] = {"cleared": true, "perfect": false}
		for id: StringName in operation.clear_unlock_ids:
			if String(id) not in profile.owned:
				profile.owned.append(String(id))
	for row: Array in FACILITIES:
		profile.deployable_levels["facility." + row[0]] = 20
	ProfileFile.replace(_save, profile, false)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		printerr("FAIL ", message)
		_failures += 1
