extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const OPERATION := preload("res://data/stages/c09_first_contact_operation.tres")

var _failed := 0
var _path := "user://c09-navigation-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_legacy_name()
	await _story_flow()
	await _tray_swipe()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("Campaign navigation checks complete. Failures: ", _failed)
	quit(0 if _failed == 0 else 1)

func _legacy_name() -> void:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	file.store_string('{"version":1,"first_clear":true,"perfect_clear":false,"funds":100}')
	file.close()
	var profile := FirstContactProgress.new(_path)
	_check(profile.snapshot().leader_name == "" and profile.snapshot().funds == 100, "Legacy C05 saves keep clear state and Funds")
	_check(not profile.set_leader_name("   "), "Blank Leader names cannot be saved")
	profile.set_leader_name("  Test Ranger  ")
	var saved := FirstContactProgress.new(_path).snapshot()
	_check(saved.leader_name == "Test Ranger" and saved.first_clear and saved.funds == 100, "Naming preserves legacy progress and trims the name")
	DirAccess.remove_absolute(_path)
	DirAccess.remove_absolute(_path + ".bak")

func _story_flow() -> void:
	var launcher := LAUNCHER.instantiate()
	launcher.save_path = _path
	# Stand-in for the future HQ unlock provider. Heat remains ineligible on T01.
	launcher.unlocked_buff_ids.assign([&"B02", &"B05"])
	root.add_child(launcher)
	await process_frame
	var content := launcher.get_node("%ScreenContent")
	var naming: Control = content.get_child(0)
	_check(naming.name == &"LeaderNaming" and naming.find_child("SaveName", true, false).disabled, "A fresh profile opens naming with Continue disabled")
	naming.find_child("LeaderName", true, false).text_submitted.emit("Talia")
	var menu: Control = content.get_child(0)
	_check(menu.name == &"MainMenu" and "Talia" in menu.get_node("%ProfileSummary").text, "Name opens Main Menu with the saved profile")
	menu.get_node("%OpenCampaign").pressed.emit()
	var story: Control = content.get_child(0)
	var first: Button = story.find_child("OpenFirstContact", true, false)
	_check(story.name == &"StoryPage" and "Available" in first.text, "Story lists the available First Contact node")
	var locked: Button = story.find_child("Locked_C1_02", true, false)
	_check(locked.disabled and story.find_child("Locked_C1_04", true, false) == null, "Control fog and prior-clear locks are independent")
	first.pressed.emit()
	var page: Control = content.get_child(0)
	var labels := _labels(page)
	for word in ["Rangers", "Facilities", "R&D support", "Thin Supply Line", "Wave 1 · 6 enemies", "Wave 2 · 8 enemies", "Forest Trespasser", "100 HP"]:
		_check(word in labels, "Simultaneous plan displays " + word)
	var choices: OptionButton = page.find_child("BuffSelector", true, false)
	_check(choices.is_item_disabled(1) and choices.is_item_disabled(2) and not choices.is_item_disabled(3), "Locked, ineligible and eligible buffs render separately")
	choices.select(3)
	choices.item_selected.emit(3)
	_check(page.plan.selected_buff.id == &"B05" and OPERATION.roster.entries[2].attack_damage == 24, "Eligible buff selects without mutating the roster")
	launcher._go_back()
	content.get_child(0).find_child("OpenFirstContact", true, false).pressed.emit()
	page = content.get_child(0)
	_check(page.find_child("BuffSelector", true, false).selected == 3, "Planning retains selections across Back and reopening")
	var unavailable := OPERATION.duplicate() as StoryOperation
	unavailable.supply_ids = []
	var illegal := OperationPlan.new(unavailable, [])
	_check(not illegal.can_start() and page.plan.can_start(), "Planning uses the same affordable-opening validator as deployment")

	page.find_child("StartOperation", true, false).pressed.emit()
	var view := content.get_child(0) as BattleScene
	view.set_physics_process(false)
	await process_frame
	await process_frame
	var battle := view.battle
	var state := battle.deployment
	_check(battle.clock.dialogue_open and state.tokens == 0, "Start opens the frozen tutorial with zero Tokens")
	_check(view.get_node("%WaveCount").text == "Wave 1/2" and view.get_node("%DefeatedCount").text == "Defeated 0/14" and view.get_node("%TokenCount").text == "0 Tokens", "HUD counters read the live encounter")
	var board: Control = view.get_node("%Board")
	var tray: Control = view.get_node("%TrayScroll")
	var title: Control = view.get_node("%Header")
	_check(title.get_global_rect().end.y <= board.get_global_rect().position.y and board.get_global_rect().end.y <= tray.get_global_rect().position.y, "HUD and tray stay outside the tactical field")
	view.get_node("%Skip").pressed.emit()
	_frames(battle, 601)
	view.get_node("%Speed").pressed.emit()
	view.get_node("%Pause").pressed.emit()
	var modal: Control = view.get_node("%PauseOverlay")
	var tick := battle.clock.tick
	_frames(battle, 100)
	_check(modal.visible and battle.clock.tick == tick and "100/100 HP" in _labels(modal), "Pause freezes combat and shows live intel")
	modal.find_child("AskAbandon", true, false).pressed.emit()
	_check(modal.find_child("ConfirmAbandon", true, false).is_visible_in_tree(), "Abandon asks for confirmation")
	modal.find_child("CancelAbandon", true, false).pressed.emit()
	_check(modal.visible and battle.clock.paused and battle.clock.get_speed() == 2, "Cancelling abandonment restores the same pause and speed")
	modal.find_child("ResumeOperation", true, false).pressed.emit()
	battle.clock.advance_frame()
	_check(not modal.visible and battle.clock.tick == tick + 2, "Resume advances the original encounter at the retained speed")
	view.get_node("%Pause").pressed.emit()
	modal.find_child("AskAbandon", true, false).pressed.emit()
	modal.find_child("ConfirmAbandon", true, false).pressed.emit()
	page = content.get_child(0)
	_check(page.name == &"PlanningPage" and page.plan.selected_buff.id == &"B05" and FirstContactProgress.new(_path).snapshot().funds == 0, "Abandon returns to retained plan and pays zero")

	page.find_child("StartOperation", true, false).pressed.emit()
	view = content.get_child(0) as BattleScene
	view.set_physics_process(false)
	view.get_node("%Skip").pressed.emit()
	battle = view.battle
	state = battle.deployment
	var entries: Array[DeploymentSpec] = page.plan.deployment_entries()
	state.deploy(entries[2], Vector2i(1, 0), 1)
	_frames(battle, 1200)
	state.deploy(entries[1], Vector2i(5, 2), -1)
	_frames(battle, 600)
	state.deploy(entries[0], Vector2i(6, 3), -1)
	_check(state.placed[&"scout"].spec.attack_damage == 26, "Committed eligible buff affects the running battle")
	_frames(battle, 14000)
	view._physics_process(0.0)
	await process_frame
	var results: Control = content.get_child(0)
	var report: Dictionary = results.report
	_check(results.name == &"OperationResults" and report.outcome == "Perfect clear" and report.defeated == 14, "Real battle completion routes to the result")
	_check(report.clear_funds == 100 and report.perfect_funds == 50 and report.balance == 150, "Result itemizes both actually credited one-time rewards")
	results.find_child("ReviewPlan", true, false).pressed.emit()
	page = content.get_child(0)
	_check(page.name == &"PlanningPage" and page.plan.selected_buff.id == &"B05", "Result returns to the same draft for retry")
	launcher._go_back()
	story = content.get_child(0)
	_check("Perfect clear" in story.find_child("OpenFirstContact", true, false).text and "Mechanical" in _labels(story), "Story reflects committed progress and the next lock")
	launcher.queue_free()

func _tray_swipe() -> void:
	var example := preload("res://scenes/battle/sample_battle.tscn").instantiate() as BattleScene
	var controller := example.get_node("%DeploymentController")
	controller.preview_budget = 60
	root.add_child(example)
	example.set_physics_process(false)
	example.size = Vector2(930, 650)
	await process_frame
	await process_frame
	var tray: HBoxContainer = example.get_node("%DeploymentTray")
	var scroller: ScrollContainer = example.get_node("%TrayScroll")
	var from: Vector2 = tray.get_child(2).get_global_rect().get_center()
	var to := from - Vector2(185, 0)
	_touch(from, true)
	var swipe := InputEventScreenDrag.new()
	swipe.position = to
	swipe.relative = to - from
	root.push_input(swipe, true)
	_touch(to, false)
	var state: DeploymentState = controller.state
	_check(scroller.scroll_horizontal > 0 and state.tokens == 60 and state.occupancy.is_empty(), "Horizontal tray swipe scrolls and never commits a deployment")
	example.queue_free()

func _touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	root.push_input(event, true)

func _frames(battle: BattleSimulation, count: int) -> void:
	for frame in count:
		battle.clock.advance_frame()

func _labels(node: Control) -> String:
	var result := PackedStringArray()
	for item: Label in node.find_children("*", "Label", true, false):
		result.append(item.text)
	return " ".join(result)

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		printerr("FAIL ", label)
		_failed += 1
