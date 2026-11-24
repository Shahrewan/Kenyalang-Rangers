extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const RANGERS := {
	"scout_sniper": [["105 HP", "Focus · 25 damage (Records locked)"], ["125 HP", "Focus · 29 damage (Records locked)"]],
	"combat_medic": [["115 HP", "25 HP healed per action", "Emergency Treatment · 67 HP healed"], ["138 HP", "29 HP healed per action", "Emergency Treatment · 78 HP healed"]],
	"outpost_mechanic": [["147 HP", "21 HP repaired per action"], ["175 HP", "24 HP repaired per action"]],
	"woods_tracker": [["105 HP", "+10 HP from Records", "23 net damage"], ["125 HP", "+10 HP from Records", "26 net damage"]],
	"strike_team": [["105 HP", "83 / 125 / 167 arrival damage per target"], ["125 HP", "96 / 144 / 192 arrival damage per target"]],
}

var _save := "user://c32-c-capture-%d.json" % OS.get_process_id()
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
		printerr("The capture profile did not load the home screen.")
		app.free()
		quit(1)
		return
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	for id: String in RANGERS:
		app._screen.find_child("Room_human_resources", true, false).pressed.emit()
		app._screen._activity.pressed.emit()
		app._screen.find_child("Unit_" + id, true, false).pressed.emit()
		var page := app._screen as DeployableUpgradePage
		page.find_child("Milestone100", true, false).pressed.emit()
		_check(_has_lines(page._current.text, RANGERS[id][0]) and _has_lines(page._preview.text, RANGERS[id][1])
			and page._target_level.text == "Target level 100" and "1,200,000" in page._balance.text
			and "Cost 939,904 Funds" in page._price.text and "After purchase 260,096 Funds" in page._price.text and not page._buy.disabled,
			id + " shows current and target output with the exact quote")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		_check(image.get_size() == root.size and image.save_png(args[0].path_join(id + ".png")) == OK, id + " native screenshot")
		page.back_requested.emit()
		app._screen.back_requested.emit()
		app._screen.back_requested.emit()
	app.free()
	for stem in [_save, _save + ".settings"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("C32-C native capture: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _has_lines(text: String, lines: Array) -> bool:
	for line: String in lines:
		if line not in text:
			return false
	return true

func _seed_profile() -> void:
	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	profile.funds = 1_200_000
	profile.rooms[String(HeadquartersCatalog.RECORDS)] = 5
	profile.encyclopaedia.perfect_chapters = ["records_chapter.woods_tracker", "records_chapter.combat_medic"]
	for operation: StoryOperation in CampaignContent.new().operations:
		if operation.stage.stage_id == &"C2-07":
			break
		profile.records[String(operation.stage.stage_id)] = {"cleared": true, "perfect": false}
		for id: StringName in operation.clear_unlock_ids:
			if String(id) not in profile.owned:
				profile.owned.append(String(id))
	for id: String in RANGERS:
		profile.deployable_levels["ranger." + id] = 20
	ProfileFile.replace(_save, profile, false)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		printerr("FAIL ", message)
		_failures += 1
