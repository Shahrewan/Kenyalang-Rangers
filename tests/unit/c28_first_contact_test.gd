extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
var _failures := 0
var _output := ""
var _path := "user://c28-first-contact-%d" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_output = args[0]
		DirAccess.make_dir_recursive_absolute(_output)
	else:
		root.size = Vector2i(960, 540)
	var perfect := await _mission("perfect", Vector2i(5, 2), Vector2i(6, 3))
	var normal := await _mission("normal", Vector2i(6, 4), Vector2i(7, 3))
	var failed := await _mission("failure")
	_check(perfect.integrity == 100 and perfect.escaped == 0 and perfect.defeated == 14 and perfect.perfect
		and perfect.settlement.credited == 10000, "Illustrated perfect clear settles the C26 award")
	_check(normal.integrity == 90 and normal.escaped == 1 and normal.defeated == 13
		and not normal.perfect and normal.settlement.credited == 10000, "Illustrated ordinary clear records exactly one escape and award")
	_check(failed.integrity == 0 and failed.escaped == 10 and failed.outcome == "Defeat"
		and failed.settlement.is_empty(), "Unopposed illustrated mission fails through ten actual escapes")
	quit(1 if _failures > 0 else 0)

func _mission(kind: String, scout := DeploymentState.NO_CELL, patrol := DeploymentState.NO_CELL) -> Dictionary:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path + "-" + kind + ".json"
	app.save_path = _path + "-legacy.json"
	var profile := CampaignSave.fresh()
	profile.leader_name = "Ari"
	ProfileFile.replace(app.campaign_save_path, profile, false)
	root.add_child(app)
	app.set_process(false)
	app._screen.get_node("%OpenCampaign").pressed.emit()
	await process_frame
	if kind == "perfect":
		await _capture("story-selection")
	app._screen.find_child("Operation_C1_01", true, false).pressed.emit()
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	await process_frame
	var board: BattleBoard = field.get_node("%Board")
	var art := board.first_contact_field
	var battle := field.battle
	var counts := {"escape": 0, "defeat": 0, "terminal": {}, "block": false, "double_block": false, "attack": false, "shot": false}
	battle.enemy_resolved.connect(func(id: int, escaped: bool) -> void:
		counts.escape += int(escaped)
		counts.defeat += int(not escaped)
		var actor: FirstContactField.Actor = art.enemies[id]
		var clip := &"Exit" if escaped else &"Defeat"
		counts.terminal[id] = not counts.terminal.has(id) and actor.terminal and actor.clip == clip \
			and (not escaped or actor.enemy.grid_cell() == board.battle_map.tunnel)
	)
	_check(art != null and field._portrait.illustrated and battle.clock.tick == 0, "C1-01 launcher opens with the authored field and radio portrait")
	if kind == "perfect":
		await _capture("briefing")
		field.get_node("%Continue").pressed.emit()
	field.get_node("%Skip").pressed.emit()
	var state := battle.deployment
	var tray: Control = field.get_node("%DeploymentTray")
	if scout != DeploymentState.NO_CELL:
		var post := DeployableLevels.definition(&"facility.logistics_post")
		_drag(_card(tray, "Logistics Post"), board, Vector2i(11, 3), 1)
		_check(state.tokens == 0 and state.occupancy.is_empty(), "A drag over the illustrated exit spends nothing")
		_drag(_card(tray, "Logistics Post"), board, Vector2i(1, 0), 1)
		_check(state.posts_deployed == 1 and state.cost_for(post) > 0 and state.build_ticks_left(state.interaction_id(Vector2i(1, 0))) == 0, "Ready Post uses the legal pair at the original tick")
		for frame in 1200:
			battle.clock.advance_frame()
		_drag(_card(tray, "Scout Sniper"), board, scout, -1)
		for frame in 600:
			battle.clock.advance_frame()
		_drag(_card(tray, "Patrolman"), board, patrol, -1)
		_check(art.rangers[&"ranger.scout_sniper"].parts.size() == 19 and art.rangers[&"ranger.patrolman"].parts.size() == 17
			and art.enemies.values().front().parts.size() == 15, "Live skeletons use all 51 approved cutouts")
		if kind == "perfect":
			await _capture("battle")
			_clock_and_facing(battle, art, patrol)
			battle.clock.set_speed(1)
	var shot_captured := false
	var block_captured := false
	var exit_captured := false
	var occlusion_checked := false
	for frame in 17000:
		battle.clock.advance_frame()
		var blockers := {}
		for actor: FirstContactField.Actor in art.enemies.values():
			if not actor.terminal and not actor.enemy.blocked_by.is_empty():
				var blocker := actor.enemy.blocked_by
				blockers[blocker] = blockers.get(blocker, 0) + 1
				counts.double_block = counts.double_block or blockers[blocker] == 2
				counts.block = counts.block or actor.clip == &"Blocked"
			counts.attack = counts.attack or actor.clip == &"Attack" or actor.clip == &"Hit"
		for effect: FirstContactField.Effect in art._effects:
			if effect.name == "shot":
				counts.shot = effect.socket == &"tranq_tool" and effect.actor.bones.has(effect.socket) and effect.origin.is_finite()
				if not _output.is_empty() and not shot_captured and kind == "perfect" and battle.clock.tick - effect.start == 6:
					shot_captured = true
					await _capture("scout-shot")
				break
		if not _output.is_empty() and not block_captured and counts.block and kind == "perfect":
			block_captured = true
			await _capture("block")
		if not _output.is_empty() and not exit_captured and kind == "normal" and not battle.active.is_empty():
			var actor: BattleEnemy = battle.active.values().back()
			if actor.distance >= actor.route.cells.size() - 1.6:
				exit_captured = true
				await _capture("woodland")
		if not _output.is_empty() and not occlusion_checked and kind == "normal" and battle.escaped == 1:
			for id: int in art.enemies:
				if art.enemies[id].clip == &"Exit":
					occlusion_checked = true
					await _verify_exit_occlusion(board, art, id)
					break
		if battle.clock.stopped:
			break
		while battle.clock.dialogue_open:
			field.get_node("%Continue" if kind == "perfect" else "%Skip").pressed.emit()
	field._refresh()
	while battle.clock.dialogue_open:
		field.get_node("%Skip").pressed.emit()
	await process_frame
	var report: Dictionary = app._screen.report
	_check(counts.escape == report.escaped and counts.defeat == report.defeated
		and counts.terminal.size() == counts.escape + counts.defeat and not counts.terminal.values().has(false),
		"Each gameplay resolution produces one terminal visual event")
	if scout != DeploymentState.NO_CELL:
		_check(counts.shot and counts.block and counts.attack, "Live attacks, block and socket-attached Scout FX occurred")
		if kind == "perfect":
			_check(counts.double_block, "Patrolman blocks two real enemies simultaneously")
	if kind == "normal" and not _output.is_empty():
		_check(occlusion_checked, "Captured occlusion on the live escape tick")
	await _capture("result-" + kind)
	app.free()
	await process_frame
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + "-" + kind + ".json" + suffix):
			DirAccess.remove_absolute(_path + "-" + kind + ".json" + suffix)
	return report

func _verify_exit_occlusion(board: BattleBoard, art: FirstContactField, id: int) -> void:
	await _capture("woodland-exit")
	var frame := root.get_texture().get_image().get_data()
	var actor := art.enemies[id]
	art.enemies.erase(id)
	board.queue_redraw()
	await RenderingServer.frame_post_draw
	var without_actor := root.get_texture().get_image().get_data()
	art.enemies[id] = actor
	_check(without_actor == frame, "The live woodland frame completely conceals the rig on the escape tick")

func _clock_and_facing(battle: BattleSimulation, art: FirstContactField, patrol: Vector2i) -> void:
	var actor := art.rangers[&"ranger.patrolman"]
	var player: AnimationPlayer = actor.rig.player
	var facing: Node2D = actor.rig.get_node("Facing")
	_check(facing.transform.x.x == -1.0, "Left-facing Patrolman uses the mirrored visual basis")
	actor.rig.set_facing(1)
	_check(facing.transform.x.x == -1.0 and actor.unit.facing == -1, "Live Patrolman facing is locked")
	var before := player.current_animation_position
	battle.clock.paused = true
	battle.clock.advance_frame()
	_check(player.current_animation_position == before, "Pause holds the animation player")
	battle.clock.paused = false
	battle.clock.set_speed(2)
	battle.clock.advance_frame()
	_check(is_equal_approx(player.current_animation_position - before, 2.0 * CombatClock.STEP_SECONDS), "2× advances exactly two combat samples")
	var scout := art.rangers[&"ranger.scout_sniper"]
	var scout_basis: Node2D = scout.rig.get_node("Facing")
	scout.rig.set_facing(-1)
	var left := art.socket_position(scout, &"tranq_tool", Vector2(31.18, 16.88))
	scout.rig.set_facing(1)
	var right := art.socket_position(scout, &"tranq_tool", Vector2(31.18, 16.88))
	_check(scout_basis.transform.x.x == 1.0 and is_equal_approx(left.y, right.y)
		and is_equal_approx((left.x + right.x) * 0.5, scout.rig.position.x), "Scout muzzle tracks its tool bone across both mirrors")
	# Advance to an affordable repeat while the original Patrolman is still on the board.
	var spec := actor.unit.spec
	var second := Vector2i(9, 3)
	while battle.deployment.tokens < spec.cost or battle.deployment.cooldown_ticks(spec.id) > 0:
		battle.clock.advance_frame()
	var tokens := battle.deployment.tokens
	_check(battle.deployment.deploy(spec, second, 1).is_empty() and battle.deployment.occupancy.has(patrol), "C26 repeat placement creates a distinct rig")
	var id := battle.deployment.interaction_id(second)
	var duplicate := art.rangers[id]
	var right_facing: Node2D = duplicate.rig.get_node("Facing")
	_check(right_facing.transform.x.x == 1.0 and battle.deployment.retreat(id) and duplicate.clip == &"Retreat", "Right-facing copy retreats independently of the original")
	_check(battle.deployment.tokens == tokens - spec.cost, "Illustrated retreat leaves the original Token rules in effect")

func _capture(file: String) -> void:
	if _output.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png(_output.path_join(file + ".png")) == OK, "Captured " + file)

func _card(tray: Control, name_starts_with: String) -> Control:
	for card: Control in tray.get_children():
		if card.is_visible_in_tree() and card.get_child(0).get_child(1).text.begins_with(name_starts_with):
			return card
	return null

func _drag(card: Control, board: BattleBoard, cell: Vector2i, facing: int) -> void:
	var start := card.get_global_rect().get_center()
	var target := board.get_global_transform_with_canvas() * (board.cell_center(cell) + Vector2(facing * 8, 0))
	var touch := InputEventScreenTouch.new()
	touch.position = start
	touch.pressed = true
	root.push_input(touch, true)
	var motion := InputEventScreenDrag.new()
	motion.position = target
	motion.relative = target - start
	root.push_input(motion, true)
	var release := InputEventScreenTouch.new()
	release.position = target
	release.pressed = false
	root.push_input(release, true)

func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
