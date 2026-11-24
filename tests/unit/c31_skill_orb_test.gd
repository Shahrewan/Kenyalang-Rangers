extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const GUARD := &"ranger.guard_veteran"
const GUARD_COPY := &"ranger.guard_veteran#2"
const SCOUT := &"ranger.scout_sniper"
const SCOUT_COPY := &"ranger.scout_sniper#2"
const MEDIC := &"ranger.combat_medic"
const CROWD := &"ranger.crowd_controller"
const CABIN := &"facility.medic_cabin"
const CALLTOWER := &"facility.specialist_calltower"
const SENTRY := &"facility.sentry_tower"
const POST := &"facility.logistics_post"
const BARRICADE := &"ranger.barricade_ops"
const ELIGIBLE := [GUARD, SCOUT, MEDIC, CROWD, CABIN, CALLTOWER, SENTRY, POST, BARRICADE]

var _checks := 0
var _failures := 0
var _capture_dir := ""
var _save := "user://c31-orb-%d.json" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var text_size := 100
	if args.size() == 3 and DisplayServer.get_name() != "headless":
		_capture_dir = args[0]
		var resolution := args[1].split("x")
		root.size = Vector2i(resolution[0].to_int(), resolution[1].to_int())
		text_size = args[2].to_int()
		DirAccess.make_dir_recursive_absolute(_capture_dir)
	else:
		root.size = Vector2i(960, 540)
	_test_geometry()
	_seed_profile()
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _save
	root.add_child(app)
	app.set_process(false)
	app.presentation.values.text = text_size
	app._restyle()
	app._screen.get_node("%OpenCampaign").pressed.emit()
	app._screen.find_child("Operation_C2_10", true, false).pressed.emit()
	app._draft.configure_campaign(app._campaign_progress, ELIGIBLE)
	app._screen.find_child("StartOperation", true, false).pressed.emit()
	var field := app._screen as CampaignBattle
	_check(field != null and field.stage.stage_id == &"C2-10", "Live Story opens the illustrated T06 finale")
	if field != null:
		await _exercise_field(field)
	app.free()
	for path in [_save, _save + ".settings"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
	print("C31 skill orbs: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _test_geometry() -> void:
	_check(is_equal_approx(BattleSkillOrb.radius_for(80.0) * 2.0, 17.0)
		and is_equal_approx(BattleSkillOrb.radius_for(60.0) * 2.0, 12.75), "Core diameter follows the 80 and 60 pixel tile scales")
	var status := BattleSkillStatus.new()
	status.mode = BattleSkillStatus.Mode.READY
	status.maximum = 4
	status.charges = 3
	status.progress = 0.50
	_check(is_equal_approx(BattleSkillOrb.ring_sweep(status), PI), "Ready face retains a half-circle for the next charge")
	status.mode = BattleSkillStatus.Mode.RECOVERING
	status.progress = 0.25
	_check(is_equal_approx(BattleSkillOrb.ring_sweep(status), PI * 0.5), "Quarter charge maps to a quarter-circle")
	for mode in [BattleSkillStatus.Mode.LOCKED, BattleSkillStatus.Mode.SPENT]:
		status.mode = mode
		_check(BattleSkillOrb.ring_sweep(status) < 0.0, "Locked and spent never render a recharge arc")
	var viewport := Rect2(0, 0, 210, 130)
	for tile in [60.0, 80.0]:
		var orbs := BattleSkillOrb.new()
		var near_top := Rect2(57, 0, 36, 38)
		var adjacent := Rect2(108, 7, 38, 39)
		var hp_bar := Rect2(94, 0, 27, 7)
		orbs.add(&"ranger.guard_veteran", near_top, status)
		orbs.add(&"ranger.guard_veteran#2", adjacent, status)
		orbs.protect(hp_bar)
		orbs.arrange(tile, viewport)
		var first := orbs.placements[&"ranger.guard_veteran"]
		var other := orbs.placements[&"ranger.guard_veteran#2"]
		_check(viewport.encloses(first.bounds) and viewport.encloses(other.bounds), "Screen-edge placement keeps both counters visible")
		_check(not first.bounds.intersects(other.bounds) and not first.bounds.intersects(hp_bar)
			and not other.bounds.intersects(hp_bar), "Adjacent copies route around one another and the HP bar")
		_check(not first.bounds.intersects(near_top) and not other.bounds.intersects(adjacent), "Placement keeps its owner's head clear")

func _exercise_field(field: CampaignBattle) -> void:
	field.set_physics_process(false)
	_skip(field)
	var sim := field.battle
	var state := sim.deployment
	# Extra Tokens for the visual fixture. The production map, waves, placement,
	# clocks, attacks, skills and Facility stock use their normal runtime paths.
	state.tokens = 260
	_drop(field, POST, Vector2i(9, 0))
	_drop(field, GUARD, Vector2i(5, 3))
	await _capture(field, "single-ranger", [GUARD])
	_drop(field, CABIN, Vector2i(1, 2))
	_drop(field, CALLTOWER, Vector2i(5, 0))
	_drop(field, SENTRY, Vector2i(9, 4))
	_drop(field, BARRICADE, Vector2i(8, 1))
	_drop(field, MEDIC, Vector2i(5, 4))
	_drop(field, SCOUT, Vector2i(9, 2))
	var visible_ids: Array[StringName] = [GUARD, CABIN, CALLTOWER, MEDIC, SCOUT]
	_check(BattleSkillStatus.read(state.placed[CABIN], state).mode == BattleSkillStatus.Mode.LOCKED
		and BattleSkillStatus.read(state.placed[SCOUT], state).mode == BattleSkillStatus.Mode.LOCKED,
		"Construction and Records locks come from the live placement")
	await _capture(field, "construction-and-records-lock", visible_ids)
	_advance_to(field, 852)
	var cabin := BattleSkillStatus.read(state.placed[CABIN], state)
	var tower := BattleSkillStatus.read(state.placed[CALLTOWER], state)
	_check(cabin.mode == BattleSkillStatus.Mode.READY and cabin.charges == 1 and cabin.just_ready
		and BattleSkillOrb.ring_sweep(cabin) > 0.0, "The Cabin flashes on the actual first kit and replenishes a second")
	_check(tower.mode == BattleSkillStatus.Mode.RECOVERING
		and BattleSkillOrb.ring_sweep(tower) > 0.0, "Built Calltower shows radial recovery before its first stock")
	await _capture(field, "facility-replenishment", visible_ids)
	_advance_to(field, 1922)
	_drop(field, GUARD, Vector2i(4, 3))
	_drop(field, SCOUT, Vector2i(9, 4))
	_drop(field, CROWD, Vector2i(1, 4))
	visible_ids.append_array([CROWD, GUARD_COPY, SCOUT_COPY])
	var mounted := state.placed[SCOUT_COPY]
	_check(mounted.mount_tower == SENTRY, "Second Scout uses the real Sentry roof registration")
	state.receive_hit(GUARD, 5, EnemyAttackProfile.Kind.RANGED)
	_check(sim.tap_unit(MEDIC) and state.select_target(Vector2i(5, 3)) and sim.confirm_skill_target(),
		"Medic spends its real one-use skill using target confirmation")
	var medic := BattleSkillStatus.read(state.placed[MEDIC], state)
	_check(medic.mode == BattleSkillStatus.Mode.SPENT and BattleSkillOrb.ring_sweep(medic) < 0.0,
		"A spent Medic carries the minus mode without a ring")
	_check(sim.active.size() >= 5, "Crowded frame contains %d live enemies from authored finale arrivals" % sim.active.size())
	await _capture(field, "crowded-finale", visible_ids)
	var used_guard := false
	var used_crowd := false
	while (not used_guard or not used_crowd) and sim.clock.tick < 2550 and not sim.clock.stopped:
		if not used_guard:
			used_guard = sim.tap_unit(GUARD)
		if not used_crowd:
			used_crowd = sim.tap_unit(CROWD)
		_advance_to(field, sim.clock.tick + 1)
	_advance_to(field, 2350)
	_check(used_guard and used_crowd, "Guard and EMP activate on enemies from the authored wave")
	var partly := BattleSkillStatus.read(state.placed[GUARD], state)
	_check(partly.mode == BattleSkillStatus.Mode.READY and partly.charges == 3
		and BattleSkillStatus.read(state.placed[GUARD_COPY], state).charges == 4
		and BattleSkillOrb.ring_sweep(partly) > 0.0, "Adjacent Guard copies show independent charges and refill")
	var crowd := BattleSkillStatus.read(state.placed[CROWD], state)
	_check(crowd.mode == BattleSkillStatus.Mode.RECOVERING, "EMP is visibly recovering after live activation")
	var sweep := BattleSkillOrb.ring_sweep(partly)
	sim.clock.paused = true
	sim.clock.advance_frame()
	_check(BattleSkillOrb.ring_sweep(BattleSkillStatus.read(state.placed[GUARD], state)) == sweep,
		"Pause holds the arc with the combat clock")
	sim.clock.paused = false
	var before := sim.clock.tick
	sim.clock.advance_frame()
	var standard := BattleSkillOrb.ring_sweep(BattleSkillStatus.read(state.placed[GUARD], state))
	sim.clock.set_speed(2)
	sim.clock.advance_frame()
	sim.clock.set_speed(1)
	var twice := BattleSkillOrb.ring_sweep(BattleSkillStatus.read(state.placed[GUARD], state))
	_check(sim.clock.tick == before + 3 and is_equal_approx(twice - standard, (standard - sweep) * 2.0),
		"1× and 2× move the ring by the right number of simulation steps")
	await _capture(field, "mixed-skill-states", visible_ids)
	var guard := state.placed[GUARD]
	guard.jammed_until = sim.clock.tick + 120
	var jammed := BattleSkillStatus.read(guard, state)
	_check(jammed.mode == BattleSkillStatus.Mode.LOCKED and jammed.progress >= 0.0
		and BattleSkillOrb.ring_sweep(jammed) < 0.0, "Jamming suppresses the visible ring while the real deadline remains")
	guard.jammed_until = 0
	guard.knocked_down_until = sim.clock.tick + 120
	_check(BattleSkillStatus.read(guard, state).mode == BattleSkillStatus.Mode.LOCKED,
		"Knockdown keeps the presentation locked")

func _drop(field: CampaignBattle, id: StringName, cell: Vector2i) -> void:
	var spec: DeploymentSpec
	for choice: DeploymentSpec in field.operation_plan.deployment_entries():
		if choice.id == id:
			spec = choice
			break
	_check(spec != null and field.battle.deployment.deploy(spec, cell, -1).is_empty(),
		"%s deploys on the normal board at %s" % [id, cell])

func _advance_to(field: CampaignBattle, tick: int) -> void:
	while field.battle.clock.tick < tick and not field.battle.clock.stopped:
		_skip(field)
		field.battle.clock.advance_frame()
	field._refresh()

func _skip(field: CampaignBattle) -> void:
	while field.battle.clock.dialogue_open:
		field.get_node("%Skip").pressed.emit()

func _seed_profile() -> void:
	var save := CampaignSave.fresh()
	save.leader_name = "Rimba"
	save.rooms["room.control_room"] = 5
	save.rooms["room.mechanical"] = 4
	save.rooms["room.human_resources"] = 4
	save.rooms["room.records"] = 4
	save.encyclopaedia.perfect_chapters = ["records_chapter.combat_medic"]
	save.chaos.personal_best = 3000
	save.chaos.earned_thresholds = ["1000", "2000", "3000"]
	save.owned.append_array([String(SENTRY), String(CALLTOWER)])
	for operation: StoryOperation in CampaignContent.new().operations:
		if operation.stage.stage_id == &"C2-10":
			break
		save.records[String(operation.stage.stage_id)] = {"cleared": true, "perfect": false}
		for id: StringName in operation.clear_unlock_ids:
			if String(id) not in save.owned:
				save.owned.append(String(id))
	ProfileFile.replace(_save, save, false)

func _capture(field: CampaignBattle, caption: String, expected: Array[StringName]) -> void:
	if _capture_dir.is_empty():
		return
	field._board.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var board := field._board
	var orbs := board._skill_orbs.placements
	var viewport := Rect2(Vector2.ZERO, board.size)
	_check(orbs.size() == expected.size() and expected.all(func(id: StringName) -> bool: return orbs.has(id)),
		caption + " draws orbs only for deployables with active skills or usable stock")
	var previous: Array[Rect2] = []
	for orb: BattleSkillOrb.Placement in orbs.values():
		_check(viewport.encloses(orb.bounds) and not orb.bounds.intersects(orb.area)
			and previous.all(func(other: Rect2) -> bool: return not other.intersects(orb.bounds)),
			caption + " keeps each orb inside the board, clear of its owner and neighboring orbs")
		previous.append(orb.bounds)
	var frame := root.get_texture().get_image()
	_check(frame.get_size() == root.size and frame.save_png(_capture_dir.path_join(caption + ".png")) == OK,
		caption + " native PNG")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
