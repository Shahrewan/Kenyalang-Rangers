extends SceneTree

const SAFE := preload("res://scripts/ui/safe_area.gd")
const STAGE := preload("res://data/stages/c05_first_contact.tres")
const RULES := preload("res://data/stages/c04_logistics_rules.tres")
const ROSTER := preload("res://data/rangers/c03_preview.tres")
const SCENE := preload("res://scenes/battle/sample_battle.tscn")

var _failed := 0
var _save_path := "user://c05-test-%d.json" % OS.get_process_id()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	_blocking()
	_normal_clear_and_loss()
	_local_save()
	await _campaign_flow()
	print("First Contact checks complete. Failures: ", _failed)
	quit(0 if _failed == 0 else 1)

func _blocking() -> void:
	var battle := BattleSimulation.new(STAGE)
	battle.deployment = DeploymentState.new(STAGE.map, battle.clock, 10, RULES)
	battle.deployment.deploy(ROSTER.entries[0], Vector2i(5, 3), -1)
	for id in range(10, 13):
		battle.active[id] = BattleEnemy.new(STAGE.waves[0].groups[0].enemy, STAGE.routes[0])
		battle.active[id].distance = 6.49
	battle.clock.advance_frame()
	_check(battle.active[10].blocked_by == &"patrolman" and battle.active[11].blocked_by == &"patrolman" and battle.active[12].blocked_by.is_empty(), "Patrolman holds two enemies and the third advances")
	_check(battle.active[12].hp == 88, "A left-facing Patrolman targets the furthest eligible ground enemy in front")
	_frames(battle, 109)
	_check(battle.deployment.placed[&"patrolman"].hp < 320, "Blocked enemies deal HP damage on combat time")

func _normal_clear_and_loss() -> void:
	var normal := BattleSimulation.new(STAGE)
	var deployment := DeploymentState.new(STAGE.map, normal.clock, 0, RULES)
	normal.deployment = deployment
	deployment.deploy(ROSTER.entries[5], Vector2i(1, 0), 1)
	_frames(normal, 1200)
	deployment.deploy(ROSTER.entries[2], Vector2i(6, 4), -1)
	_frames(normal, 600)
	deployment.deploy(ROSTER.entries[0], Vector2i(7, 3), -1)
	_frames(normal, 12500)
	_check(normal.outcome == BattleSimulation.Outcome.WON and normal.integrity == 90 and normal.escaped == 1 and normal.defeated == 13 and not normal.is_perfect(), "Alternate deployment earns a normal clear with one 10-Integrity escape")

	var loss := BattleSimulation.new(STAGE)
	_frames(loss, 16000)
	_check(loss.outcome == BattleSimulation.Outcome.LOST and loss.integrity == 0 and loss.escaped == 10, "An undefended First Contact ends in defeat at zero Integrity")

func _local_save() -> void:
	var path := _save_path + ".unit"
	var first := FirstContactProgress.new(path)
	_check(first.record_clear(false, 100, 50) == 100, "First normal clear persists the base reward")
	var replay := FirstContactProgress.new(path)
	_check(replay.snapshot().first_clear and not replay.snapshot().perfect_clear and replay.snapshot().funds == 100, "Relaunch loads the first-clear flag and Funds")
	_check(replay.record_clear(true, 100, 50) == 50, "Later perfect clear grants only the remaining bonus")
	var repeat := FirstContactProgress.new(path)
	_check(repeat.snapshot().perfect_clear and repeat.snapshot().funds == 150 and repeat.record_clear(true, 100, 50) == 0, "Perfect flag survives relaunch and rewards are one-time")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("invalid save")
	file.close()
	_check(FirstContactProgress.new(path).snapshot().funds == 100, "Unreadable primary falls back to the last readable save")
	_remove_owned_save(path)

func _campaign_flow() -> void:
	var scene := SCENE.instantiate() as BattleScene
	scene.campaign = true
	scene.stage = STAGE
	scene.save_path = _save_path
	root.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	# Simulate an inset cutout on a scaled 960×540 landscape display.
	var margins := SAFE.safe_margins(
		Rect2(0, 0, 1280, 720), Rect2(56, 12, 884, 516),
		Transform2D(0.0, Vector2(0.75, 0.75), 0.0, Vector2.ZERO)
	)
	scene.position = Vector2(margins.x, margins.y)
	scene.size = Vector2(1280 - margins.x - margins.z, 720 - margins.y - margins.w)
	scene.set_physics_process(false)
	await process_frame
	await process_frame
	var battle := scene.battle
	var state := battle.deployment
	var board: BattleBoard = scene.get_node("%Board")
	var tray: Control = scene.get_node("%DeploymentTray")
	var overlay: Control = scene.get_node("%Dialogue")
	_check(scene.get_global_rect().encloses(board.get_global_rect()) and scene.get_global_rect().encloses(tray.get_global_rect()) and board.tile_size() >= 48.0, "Simulated small landscape and notch keep field and tray within safe bounds")
	_check(overlay.visible and state.tokens == 0 and not scene.get_node("%DefeatEnemy").visible, "Campaign opens at zero Tokens with the tutorial and hides debug defeat")
	_frames(battle, 180)
	_check(battle.clock.tick == 0 and battle.active.is_empty(), "Tutorial freezes spawns and the combat clock")
	scene.get_node("%Skip").pressed.emit()
	_check(not overlay.visible, "Skip closes the campaign tutorial")
	_drag(tray.get_child(5), board, Vector2i(4, 3), 0)
	_check(state.tokens == 0 and state.occupancy.is_empty(), "Invalid Starter Post drop spends nothing")
	_drag(tray.get_child(5), board, Vector2i(1, 0), 0)
	_check(state.posts_deployed == 1 and state.tokens == 0 and state.build_ticks_left(&"facility.logistics_post#1") == 0, "Campaign touch places one free instant Starter Post")

	_frames(battle, 600)
	_check(state.tokens == 9 and battle.active.is_empty(), "D01 yields nine Tokens before the first wave")
	_drag(tray.get_child(2), board, Vector2i(5, 2), 0)
	_check(state.tokens == 9 and not state.placed.has(&"scout"), "Unaffordable touch deployment preserves Tokens")
	scene.get_node("%Pause").pressed.emit()
	_frames(battle, 300)
	_check(battle.clock.tick == 600 and state.tokens == 9, "Pause holds both waves and Post generation")
	scene.get_node("%Pause").pressed.emit()
	_frames(battle, 600)
	_drag(tray.get_child(2), board, Vector2i(5, 2), 0)
	_frames(battle, 600)
	_drag(tray.get_child(0), board, Vector2i(6, 3), -8)
	_check(state.placed.has(&"scout") and state.placed.has(&"patrolman") and state.placed[&"patrolman"].facing == -1, "Touch deploys Scout and a left-facing Patrolman")

	_frames(battle, 14000)
	scene._physics_process(0.0)
	_check(battle.is_perfect() and battle.defeated == 14 and battle.integrity == 100, "Full two-wave Campaign clears with 14 defeated and zero escapes")
	var tip: Label = scene.get_node("%MissionTip")
	_check("150 Funds" in tip.text and FirstContactProgress.new(_save_path).snapshot().perfect_clear, "Campaign result saves the visibly provisional perfect and first-clear Funds")
	scene.get_node("%Retry").pressed.emit()
	_check(scene.battle.integrity == 100 and scene.battle.deployment.tokens == 0 and scene.battle.deployment.placed.is_empty() and overlay.visible, "Restart resets combat and retains the tutorial loadout")
	scene.get_node("%Continue").pressed.emit()
	await process_frame
	state = scene.battle.deployment
	_drag(tray.get_child(5), board, Vector2i(1, 0), 0)
	_frames(scene.battle, 1200)
	_drag(tray.get_child(0), board, Vector2i(6, 3), -8)
	var point := board.get_global_transform_with_canvas() * board.cell_center(Vector2i(6, 3))
	_touch(point, true)
	var hold_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - hold_start < 380:
		await process_frame
	await process_frame
	var retreat: Button = scene.get_node("%Retreat")
	_check(retreat.visible, "Campaign hold exposes Retreat")
	_touch(point, false)
	retreat.pressed.emit()
	_check(not state.placed.has(&"patrolman") and state.cooldown_ticks(&"patrolman") > 0, "Campaign Retreat frees its tile and starts cooldown")
	_remove_owned_save(_save_path)
	scene.queue_free()

func _frames(battle: BattleSimulation, count: int) -> void:
	for frame in count:
		battle.clock.advance_frame()

func _drag(card: Control, board: BattleBoard, cell: Vector2i, offset: float) -> void:
	var from := card.get_global_rect().get_center()
	var to := board.get_global_transform_with_canvas() * (board.cell_center(cell) + Vector2(offset, 0))
	_touch(from, true)
	var motion := InputEventScreenDrag.new()
	motion.position = to
	motion.relative = to - from
	root.push_input(motion, true)
	_touch(to, false)

func _touch(at: Vector2, down: bool) -> void:
	var pointer := InputEventScreenTouch.new()
	pointer.position = at
	pointer.pressed = down
	root.push_input(pointer, true)

func _remove_owned_save(path: String) -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)

func _check(ok: bool, description: String) -> void:
	if ok:
		print("PASS ", description)
	else:
		printerr("FAIL ", description)
		_failed += 1
