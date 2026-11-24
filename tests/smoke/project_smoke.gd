extends SceneTree

const SafeArea := preload("res://scripts/ui/safe_area.gd")
const MENU := preload("res://scenes/menus/main_menu.tscn")
const SAMPLE := preload("res://scenes/battle/sample_battle.tscn")

var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var version_pin := FileAccess.get_file_as_string("res://.godot-version").strip_edges()
	var info := Engine.get_version_info()
	var version := "%d.%d.%d" % [info.major, info.minor, info.patch]
	_check(version == version_pin and info.status == "stable", "Stable editor version matches pin")
	_check(ProjectSettings.get_setting("display/window/handheld/orientation") == 0, "Landscape orientation")
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Compatibility renderer")

	var bounds := Rect2(0, 0, 1280, 720)
	var scaled := Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2.ZERO)
	var cutout := Rect2(60, 30, 1800, 1050)
	_check(SafeArea.safe_margins(bounds, cutout, scaled) == Vector4i(64, 44, 64, 24), "Physical cutout converts to logical margins")
	_check(SafeArea.safe_margins(bounds, Rect2(), scaled) == Vector4i(24, 24, 24, 24), "Missing safe area uses base margins")
	var offset := Transform2D(0.0, Vector2(1.0, 1.0), 0.0, Vector2(100, 50))
	_check(SafeArea.safe_margins(bounds, Rect2(0, 0, 1480, 820), offset) == Vector4i(24, 24, 24, 24), "Safe area clips to the logical viewport")

	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	var main := load(main_path) as PackedScene
	if main == null:
		_check(false, "Configured main scene loads")
		_finish()
		return

	var path := "user://project-smoke-%d.json" % OS.get_process_id()
	var profile := FirstContactProgress.new(path)
	profile.set_leader_name("Smoke test")
	var launcher := main.instantiate()
	launcher.first_contact_trial = true
	launcher.save_path = path
	root.add_child(launcher)
	await process_frame
	var container := launcher.get_node("%ScreenContent")
	var menu: Control = container.get_child(0)
	_check(menu.scene_file_path == MENU.resource_path, "Launch opens Main Menu")

	_check(menu.get_node_or_null("%OpenSample") == null, "The player menu has no testing mode entry")
	launcher.show_sample()
	var sample: Control = container.get_child(0)
	_check(sample.scene_file_path == SAMPLE.resource_path, "The sample scene still opens directly for testing")
	var back: Button = sample.get_node_or_null("%BackToMenu")
	if back != null:
		back.pressed.emit()
		_check(container.get_child(0).scene_file_path == MENU.resource_path, "Back returns to Main Menu")
	else:
		_check(false, "Sample battle has a Back button")
	DirAccess.remove_absolute(path)
	_finish()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		printerr("FAIL ", label)
		_failures += 1

func _finish() -> void:
	print("Project smoke checks complete. Failures: ", _failures)
	quit(0 if _failures == 0 else 1)
