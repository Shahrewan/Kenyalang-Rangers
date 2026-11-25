extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const POST := &"facility.logistics_post"
const SCOUT := &"ranger.scout_sniper"
const PATROL := &"ranger.patrolman"
const MEDIC := &"ranger.combat_medic"
const TURRET := &"facility.sonic_turret"
const STAGE := &"C1-02"
const FIRST_POST := Vector2i(1, 0)
const REPEAT_POST := Vector2i(5, 0)

var _checks := 0
var _failures := 0
var _output := ""
var _save := "user://c28-b-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		root.size = Vector2i(960, 540)
	else:
		_output = args[0]
		DirAccess.make_dir_recursive_absolute(_output)
	var profile := CampaignSave.fresh()
	profile.leader_name = "Ari"
	ProfileFile.replace(_save, profile, false)
	var app := _launcher()
	var progress: CampaignProgress = app._campaign_progress
	var first: StoryOperation = app._campaign.operation(&"C1-01")
	app.show_story()
	_check(_operation(app, "C1_02").disabled, "C1-02 requires the First Contact clear")
	progress.begin_attempt(first)
	progress.complete(first, false)
	app.show_story()
	_operation(app, "C1_02").pressed.emit()
	_check(app._screen.find_child("StartOperation", true, false).disabled, "Normal opening requires a legally affordable unit")
	_check(progress.purchase_room(HeadquartersCatalog.MECHANICAL).is_empty() and progress.funds() == 0,
		"The existing First Contact Funds pay for Mechanical")
	await _play_fixture(app)
	app.free()
	await process_frame
	app = _launcher()
	_check(app._campaign_progress.record_for(STAGE) == {"cleared": true, "perfect": false}
		and app._campaign_progress.snapshot().pending_attempt.is_empty()
		and app._campaign_progress.owns(MEDIC) and app._campaign_progress.owns(TURRET) and app._campaign_progress.funds() == 30000,
		"Reload preserves the clear, unlocks and its paid 30,000 Funds")
	app.show_story()
	_operation(app, "C1_03").pressed.emit()
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var next := app._screen as CampaignBattle
	next.set_physics_process(false)
	_check(next.stage.stage_id == &"C1-03" and next._board.first_contact_field != null,
		"C1-02 clear opens the illustrated Narrow Escape operation")
	app._campaign_progress.abandon_attempt()
	await _construction_replay(app)
	app.free()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(_save + suffix)
	print("Hold the Line: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

func _launcher() -> Control:
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _save
	app.save_path = _save + ".legacy"
	root.add_child(app)
	app.set_process(false)
	return app

func _operation(app: Control, key: String) -> Button:
	return app._screen.find_child("Operation_" + key, true, false)

func _plan(app: Control) -> OperationPlan:
	app.show_story()
	_operation(app, "C1_02").pressed.emit()
	return app._screen.plan

func _open(app: Control) -> CampaignBattle:
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	return field

func _play_fixture(app: Control) -> void:
	var plan := _plan(app)
	var catalog := FirstContactSkin.poacher_art()
	var portrait: TextureRect = app._screen.find_child("E02Badge", true, false)
	var badge: Texture2D = portrait.texture if portrait != null else null
	_check(badge != null and badge.resource_path == catalog.badge, "Planning uses the W29 E02 badge")
	_check(plan.operation.fixed_debuff_ids == [&"D02"] and plan.operation.supply_ids.is_empty(), "D02 and the ordinary loadout come from the original operation")
	await _capture("planning-intel", app._screen)
	var field := _open(app)
	await process_frame
	var battle := field.battle
	var board := field._board
	var art := board.first_contact_field
	var state := battle.deployment
	_check(art != null and field._portrait.illustrated and not board.show_starter_guide
		and not state.rules.starter_only and state.rules.yield_percent == 100 and battle.effects.amount(&"enemy_speed_percent") == 10.0,
		"C1-02 uses illustrated T01, an ordinary Post and D02 enemy speed")
	_check(field._portrait.identity == "portrait.leader" or field._portrait.identity == "portrait.manager", "Opening uses a shared radio portrait")
	battle.clock.advance_frame()
	_check(battle.clock.tick == 0 and state.tokens == 0, "Opening dialogue holds the shared clock")
	field.get_node("%Continue").pressed.emit()
	_skip(field)
	_drop(field, POST, Vector2i(11, 3))
	_check(state.tokens == 0 and state.occupancy.is_empty(), "Invalid Post placement allocates no cells or Tokens")
	_drop(field, POST, FIRST_POST)
	_check(state.posts_deployed == 1 and state.tokens == 0 and state.build_ticks_left(state.interaction_id(FIRST_POST)) == 0,
		"The equipped ordinary Post is free and ready on its first legal pair")
	var queue := [[SCOUT, Vector2i(5, 2)], [PATROL, Vector2i(6, 3)], [SCOUT, Vector2i(6, 2)], [PATROL, Vector2i(9, 3)], [SCOUT, Vector2i(8, 2)]]
	var terminal := {}
	battle.enemy_resolved.connect(func(id: int, escaped: bool) -> void:
		var actor: FirstContactField.Actor = art.enemies.get(id)
		terminal[id] = not terminal.has(id) and actor != null and actor.terminal \
			and actor.clip == (&"Exit" if escaped else &"Defeat") \
			and (not escaped or actor.enemy.grid_cell() == board.battle_map.tunnel)
	)
	var states := {}
	var walking_together := false
	var tested_clock := false
	var tested_occlusion := false
	var faction_facing := {}
	var vertical_facing := false
	var blocked_together := false
	var near_fist := false
	for frame in 15000:
		battle.clock.advance_frame()
		_skip(field)
		if not queue.is_empty():
			var spec: DeploymentSpec = field.get_node("%DeploymentController")._offered[queue[0][0]]
			if state.placement_error(spec, queue[0][1]).is_empty():
				_drop(field, queue[0][0], queue[0][1])
				queue.pop_front()
		var e01 := false
		var e02: FirstContactField.Actor
		var blocks := {}
		for id: int in art.enemies:
			var actor := art.enemies[id]
			if actor.enemy.definition.enemy_id == &"E01":
				e01 = e01 or not actor.terminal
			else:
				states[actor.clip] = true
				if not actor.terminal:
					e02 = actor
					var direction: Node2D = actor.rig.get_node("Facing")
					var x := direction.transform.x.x
					faction_facing[x] = true
					if actor.enemy.grid_cell() == Vector2i(4, 2):
						vertical_facing = vertical_facing or x == 1.0
			if not actor.terminal and not actor.enemy.blocked_by.is_empty():
				blocks[actor.enemy.blocked_by] = blocks.get(actor.enemy.blocked_by, 0) + 1
				blocked_together = blocked_together or blocks[actor.enemy.blocked_by] == 2
		for effect: FirstContactField.Effect in art._effects:
			near_fist = near_fist or (effect.name == "poacher_strike" and effect.socket == &"hand_near"
				and effect.actor.bones.has(effect.socket))
		if e01 and e02 != null and e02.enemy.grid_position().x >= 1.0 and not tested_clock:
			walking_together = e02.parts.size() == 15 and e02.rig.scene_file_path == catalog.rig \
				and e02.rig.contract_path == catalog.animation and _texture_count(e02) == 15
			await _capture("mixed-wave", field)
			field.get_node("%Pause").pressed.emit()
			var pause_badge: TextureRect = field._pause_overlay.find_child("E02Badge", true, false)
			var before: float = e02.rig.player.current_animation_position
			var tick := battle.clock.tick
			battle.clock.advance_frame()
			_check(tick == battle.clock.tick and before == e02.rig.player.current_animation_position
				and pause_badge != null and pause_badge.texture == badge, "Pause freezes E02 and displays the same W29 badge")
			await _capture("pause-intel", field)
			field._pause_overlay.find_child("ResumeOperation", true, false).pressed.emit()
			field.get_node("%Speed").pressed.emit()
			var clip: Animation = e02.rig.player.get_animation(e02.clip)
			battle.clock.advance_frame()
			_check(battle.clock.tick == tick + 2 and is_equal_approx(e02.rig.player.current_animation_position,
				fposmod(before + 2.0 * CombatClock.STEP_SECONDS, clip.length)), "2× advances E02 by two combat samples")
			field.get_node("%Speed").pressed.emit()
			tested_clock = true
		if battle.escaped == 1 and not tested_occlusion:
			tested_occlusion = true
			if not _output.is_empty():
				await _compare_exit(field, art)
		if battle.clock.stopped:
			break
	_check(walking_together and blocked_together, "E01 and E02 coexist with independent rigs and stacked blockers")
	_check(states.has(&"Move") and states.has(&"Blocked") and states.has(&"Attack") and states.has(&"Hit")
		and states.has(&"Defeat") and vertical_facing and faction_facing.has(1.0) and near_fist,
		"E02 walks, holds its facing through the turn, blocks, strikes from the fist, takes hits and falls")
	_check(queue.is_empty() and battle.integrity == 90 and battle.defeated == 17 and battle.escaped == 1
		and battle.clock.tick == 8169 and battle.outcome == BattleSimulation.Outcome.WON and not battle.is_perfect(),
		"Fixture resolves at tick %d with %d defeated, %d escaped and %d Integrity" % [battle.clock.tick, battle.defeated, battle.escaped, battle.integrity])
	_check(terminal.size() == 18 and not terminal.values().has(false) and tested_occlusion,
		"All 18 enemies receive exactly one matching terminal visual")
	field._refresh()
	_skip(field)
	await process_frame
	var report: Dictionary = app._screen.report
	_check(report.stage_id == STAGE and report.outcome == "Clear" and report.integrity == 90 and report.defeated == 17
		and report.escaped == 1 and not report.perfect and not report.save_failed, "Report matches the live ordinary clear and save")
	_check(report.settlement.first_clear and report.settlement.credited == 30000
		and report.settlement.awards == {"first_clear_funds": 30000} and report.settlement.unlocked == [MEDIC, TURRET],
		"Settlement preserves the award key and both approved unlock IDs")
	_check(_has_texture(app._screen, "result_clear"), "C1-02 uses the shared ordinary-clear mark")
	await _capture("normal-result", app._screen)

func _construction_replay(app: Control) -> void:
	var plan := _plan(app)
	var post: DeploymentSpec
	for spec in plan.choices:
		if spec.id == SCOUT:
			plan.select_unit(spec, false)
		elif spec.id == MEDIC:
			_check(plan.select_unit(spec, true), "Reloaded campaign can equip the legally unlocked Combat Medic")
		elif spec.id == POST:
			post = spec
	plan.select_unit(post, false)
	_check(not plan.can_start(), "Without the optional Post, this zero-Token plan retains its opening gate")
	plan.select_unit(post, true)
	app._screen._refresh_plan()
	var field := _open(app)
	await process_frame
	_skip(field)
	var state := field.battle.deployment
	var clock := field.battle.clock
	var art := field._board.first_contact_field
	_drop(field, POST, FIRST_POST)
	_advance_until(field, func() -> bool: return state.tokens >= state.cost_for(post))
	var tokens := state.tokens
	_drop(field, POST, REPEAT_POST)
	var id := state.interaction_id(REPEAT_POST)
	var remaining := state.build_ticks_left(id)
	var cost := tokens - state.tokens
	_check(remaining == CombatClock.ticks_for(post.build_seconds) and cost > 0 and state.occupancy[REPEAT_POST + Vector2i.RIGHT] == id
		and state.placed[id].hp == post.max_hp and not art._effects.any(func(fx: FirstContactField.Effect) -> bool:
			return fx.name == "post_ready" and fx.cell == Vector2(REPEAT_POST) + Vector2(0.5, 0)),
		"Paid repeat Post occupies two cells at full HP with a building countdown and no Ready pulse")
	await _capture("post-construction", field)
	field.get_node("%Pause").pressed.emit()
	clock.advance_frame()
	_check(state.build_ticks_left(id) == remaining, "Pause holds repeat construction")
	field._pause_overlay.find_child("ResumeOperation", true, false).pressed.emit()
	field.get_node("%Speed").pressed.emit()
	clock.advance_frame()
	_check(clock.get_speed() == 2 and state.build_ticks_left(id) == remaining - 2, "2× decrements construction by two combat ticks")
	field.get_node("%Speed").pressed.emit()
	var cooldown := state.cooldown_ticks(POST)
	var before_cancel := state.tokens
	await _hold(field, REPEAT_POST)
	_check(field.get_node("%Retreat").visible and field.get_node("%Retreat").text == "Cancel build", "Touch hold exposes Cancel build for the unfinished Post")
	field.get_node("%Retreat").pressed.emit()
	_check(state.tokens == before_cancel + cost and not state.placed.has(id) and state.interaction_id(REPEAT_POST).is_empty()
		and state.interaction_id(FIRST_POST) != &"" and state.cooldown_ticks(POST) == cooldown, "Cancel refunds the exact spend and leaves the other Post and shared cooldown")
	_advance_until(field, func() -> bool: return state.cooldown_ticks(POST) == 0 and state.tokens >= state.cost_for(post))
	_drop(field, POST, REPEAT_POST)
	var rebuilt := state.interaction_id(REPEAT_POST)
	_check(not rebuilt.is_empty() and rebuilt != id and state.build_ticks_left(rebuilt) > 0, "Later legal Post placement gets a new instance and construction deadline")
	_advance_until(field, func() -> bool: return state.build_ticks_left(rebuilt) == 0)
	await _capture("post-ready", field)
	var medic: DeploymentSpec = field.get_node("%DeploymentController")._offered[MEDIC]
	_advance_until(field, func() -> bool: return state.tokens >= state.cost_for(medic))
	_drop(field, MEDIC, Vector2i(6, 2))
	var medic_id := state.interaction_id(Vector2i(6, 2))
	_check(not medic_id.is_empty() and state.placed[medic_id].spec.id == MEDIC
		and not art.rangers.has(medic_id), "Unlocked Combat Medic deploys via the labeled fallback")
	var turret: DeploymentSpec = field.get_node("%DeploymentController")._offered[TURRET]
	_advance_until(field, func() -> bool: return state.tokens >= state.cost_for(turret))
	_drop(field, TURRET, Vector2i(8, 0))
	var turret_id := state.interaction_id(Vector2i(8, 0))
	_advance_until(field, func() -> bool: return state.build_ticks_left(turret_id) == 0)
	_check(not turret_id.is_empty() and state.placed[turret_id].spec.id == TURRET and state.build_ticks_left(turret_id) == 0,
		"Unlocked Sonic Turret completes via the labeled Facility fallback")
	await _capture("loadout-fallback", field)
	var poacher_exits := 0
	for frame in 12000:
		clock.advance_frame()
		_skip(field)
		if art.enemies.values().any(func(actor: FirstContactField.Actor) -> bool:
			return actor.enemy.definition.enemy_id == &"E02" and actor.clip == &"Exit"):
			poacher_exits += 1
			break
	_check(poacher_exits == 1, "E02 enters its authored Exit clip on an actual escape")

func _advance_until(field: CampaignBattle, reached: Callable) -> void:
	for frame in 6000:
		if reached.call() or field.battle.clock.stopped:
			return
		field.battle.clock.advance_frame()
		_skip(field)

func _skip(field: CampaignBattle) -> void:
	while field.battle.clock.dialogue_open:
		field.get_node("%Skip").pressed.emit()

func _texture_count(actor: FirstContactField.Actor) -> int:
	var paths := {}
	for part: Sprite2D in actor.parts:
		if part.texture != null:
			paths[part.texture.resource_path] = true
	return paths.size()

func _has_texture(node: Node, key: String) -> bool:
	var expected := FirstContactSkin.new().region("interface", key).region
	for child: Node in node.find_children("*", "TextureRect", true, false):
		if child.texture is AtlasTexture and child.texture.region == expected:
			return true
	return false

func _drop(field: CampaignBattle, id: StringName, cell: Vector2i) -> void:
	var controller = field.get_node("%DeploymentController")
	var index: int = controller._entries.find_custom(func(spec: DeploymentSpec) -> bool: return spec.id == id)
	var card: Control = controller._cards[index]
	var point := card.get_global_rect().get_center()
	var target := field._board.get_global_transform_with_canvas() * (field._board.cell_center(cell) - Vector2(8, 0))
	_touch(point, true)
	var motion := InputEventScreenDrag.new()
	motion.position = target
	motion.relative = target - point
	root.push_input(motion, true)
	_touch(target, false)

func _hold(field: CampaignBattle, cell: Vector2i) -> void:
	var point := field._board.get_global_transform_with_canvas() * field._board.cell_center(cell)
	_touch(point, true)
	await create_timer(0.4).timeout
	_touch(point, false)

func _touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)

func _capture(filename: String, screen: Control) -> void:
	if _output.is_empty():
		return
	if screen is CampaignBattle:
		screen._refresh()
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(_output.path_join(filename + ".png")) == OK,
		"Captured " + filename)

func _compare_exit(field: CampaignBattle, art: FirstContactField) -> void:
	await _capture("woodland-escape", field)
	var frame := root.get_texture().get_image().get_data()
	var exit_id := -1
	for id: int in art.enemies:
		if art.enemies[id].clip == &"Exit":
			exit_id = id
			break
	if exit_id == -1:
		_check(false, "Found the terminal rig on the live escape tick")
		return
	var actor := art.enemies[exit_id]
	art.enemies.erase(exit_id)
	field._board.queue_redraw()
	await RenderingServer.frame_post_draw
	var without_actor := root.get_texture().get_image().get_data()
	art.enemies[exit_id] = actor
	_check(frame == without_actor, "The exact escape frame contains no remaining body, HP or outline")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("PASS ", message)
	else:
		_failures += 1
		printerr("FAIL ", message)
