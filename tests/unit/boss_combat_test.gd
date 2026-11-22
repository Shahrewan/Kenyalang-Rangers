extends SceneTree

const CATALOG: EnemyCatalog = preload("res://data/bosses/catalog.tres")
const CAPTAIN: BossSpec = preload("res://data/bosses/diversion_captain.tres")
const FOREMAN: BossSpec = preload("res://data/bosses/illegal_logging_foreman.tres")
const LEADER: BossSpec = preload("res://data/bosses/poacher_leader.tres")
const ARENA: BattleStage = preload("res://tests/fixtures/c11_facility_stage.tres")
const BARRICADE: RangerSpec = preload("res://tests/fixtures/c11_barricade_target.tres")
const SONIC: FacilitySpec = preload("res://data/facilities/sonic_turret.tres")
const FIREBREAK: FacilitySpec = preload("res://data/facilities/firebreak_beacon.tres")
const SANDBOX := preload("res://scenes/qa/enemy_sandbox.tscn")

var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_catalog()
	for boss: BossSpec in CATALOG.entries:
		_boss_lifecycle(boss)
	_captain_capture()
	_foreman_protection()
	_leader_phases()
	await _sandbox_flow()
	print("Boss checks complete. Failures: ", _failed)
	quit(0 if _failed == 0 else 1)

func _catalog() -> void:
	_check(CATALOG.entries == [CAPTAIN, FOREMAN, LEADER], "Boss catalog contains the three canonical templates")
	_check(CAPTAIN.operation_id == &"C1-05" and CAPTAIN.max_hp == 2500 and CAPTAIN.chaos_points == 200 and CAPTAIN.attack_damage == 28 and CAPTAIN.attack_seconds == 1.8, "Captain carries the sourced mission, HP, damage, cadence and score")
	_check(FOREMAN.operation_id == &"C2-08" and FOREMAN.max_hp == 8000 and FOREMAN.chaos_points == 300 and FOREMAN.attack_damage == 42 and FOREMAN.attack_seconds == 2.5 and FOREMAN.technological, "Foreman carries the sourced baseline and Technological tag")
	_check(LEADER.operation_id == &"C2-10" and LEADER.max_hp == 13000 and LEADER.chaos_points == 500 and LEADER.attack_damage == 60 and LEADER.attack_seconds == 2.0, "Leader carries the sourced mission, HP, damage, cadence and score")
	for boss: BossSpec in CATALOG.entries:
		_check(not boss.is_siege_capable() and _stage(boss).validation_error().is_empty(), "%s has valid phases and ordinary attacks" % boss.display_name)
	var invalid := _stage(FOREMAN)
	invalid.capture_boss_id = FOREMAN.enemy_id
	_check(not invalid.validation_error().is_empty() and _stage(CAPTAIN, true).validation_error().is_empty(), "The capture objective requires its capturable boss in the final singular wave")

func _boss_lifecycle(boss: BossSpec) -> void:
	var battle := _battle(boss)
	var clock := battle.clock
	var name := boss.display_name
	var briefing: Array[StringName] = []
	battle.boss_intro.connect(func(_id: int, definition: BossSpec) -> void:
		briefing.append(definition.enemy_id)
		clock.dialogue_open = true
	)
	battle.clock.paused = true
	_frames(battle, 40)
	_check(battle.active.is_empty(), "%s cannot spawn during Pause" % name)
	battle.clock.paused = false
	battle.clock.set_speed(2)
	_frames(battle, 1)
	var actor := battle.active[1]
	_check(briefing == [boss.enemy_id] and actor.hp == boss.max_hp and battle.clock.tick == 1, "%s intro stops the second combat step at 2×" % name)
	battle.damage_enemy(1, 500)
	_frames(battle, 100)
	_check(actor.hp == boss.max_hp and actor.distance == 0.0, "%s HP and movement stay held by the intro" % name)
	battle.clock.dialogue_open = false
	battle.clock.set_speed(1)
	var state := battle.deployment
	state.deploy(SONIC, Vector2i(0, 1), 1)
	state.deploy(BARRICADE, Vector2i(1, 2), -1)
	actor.distance = 0.49
	_frames(battle, 1 + CombatClock.ticks_for(boss.attack_seconds))
	_check(state.placed[BARRICADE.id].hp == BARRICADE.max_hp - boss.attack_damage and state.placed[SONIC.id].hp == SONIC.max_hp, "%s hits a Ranger and leaves Facility HP alone" % name)
	battle.damage_enemy(1, boss.max_hp)
	_check(battle.defeated == 1 and battle.is_perfect() and battle.expected_enemy_count == 1, "%s can finish a singular boss wave" % name)

	battle = _battle(boss)
	_frames(battle, 1)
	actor = battle.active[1]
	actor.distance = actor.route.cells.size() - 1.001
	_frames(battle, 1)
	var expected := 0 if boss.escape_causes_defeat else 100 - boss.escape_penalty
	_check(battle.escaped == 1 and battle.integrity == expected and not battle.is_perfect(), "%s escape applies its specified outcome" % name)

func _captain_capture() -> void:
	var battle := _battle(CAPTAIN, true)
	var captured: Array[int] = []
	battle.boss_captured.connect(func(id: int) -> void: captured.append(id))
	_frames(battle, 1)
	battle.damage_enemy(1, 750)
	_frames(battle, 1)
	_check(battle.active[1].phase_index == 1 and battle.expected_enemy_count == 3, "Captain schedules two allies once at its 70% threshold")
	_frames(battle, 60)
	var reinforcement := battle.active[2]
	var distance := reinforcement.distance
	_frames(battle, 1)
	_check(reinforcement.definition.enemy_id == &"E02" and is_equal_approx(reinforcement.distance - distance, reinforcement.definition.tiles_per_second * 1.2 / 60.0), "A nearby Poacher receives the Captain's movement support")
	battle.clock.paused = true
	_frames(battle, 300)
	_check(battle.active.size() == 2 and battle.clock.tick == 63, "Pause holds the Captain's pending reinforcement")
	battle.clock.paused = false
	battle.damage_enemy(1, 1750)
	_check(battle.captured_boss_id == CAPTAIN.enemy_id and captured == [1] and battle.active.is_empty() and battle.is_perfect(), "Story capture ends the operation and withdraws the remaining support")
	_check(battle.defeated == 1 and battle.escaped == 0 and battle.expected_enemy_count == 1, "Withdrawn support contributes neither defeats nor escapes")

	battle = _battle(CAPTAIN, true)
	_frames(battle, 1)
	battle.active[1].distance = 10.999
	_frames(battle, 1)
	_check(battle.outcome == BattleSimulation.Outcome.LOST and battle.escaped == 1, "Losing a required capture target defeats the operation")

	battle = _battle(CAPTAIN)
	_frames(battle, 1)
	battle.damage_enemy(1, 750)
	_frames(battle, 1)
	battle.damage_enemy(1, 1750)
	_check(battle.active.is_empty() and battle.outcome == BattleSimulation.Outcome.RUNNING, "A regular boss wave stays open for scheduled support after the boss is defeated")
	_frames(battle, 120)
	_check(battle.active.size() == 2 and battle.expected_enemy_count == 3, "Scheduled support still reaches the field in a regular boss wave")
	for id in battle.active.keys():
		battle.damage_enemy(id, battle.active[id].hp)
	_check(battle.is_perfect() and battle.defeated == 3, "A regular boss wave only clears after all support resolves")

func _foreman_protection() -> void:
	var battle := _battle(FOREMAN, false, true)
	battle.deployment.deploy(FIREBREAK, Vector2i(0, 1), 1)
	_frames(battle, 421)
	var actor := battle.active[1]
	var before := battle.heat
	_check(is_equal_approx(before, 10.0 * 0.6 / 60.0), "Foreman increases Heat with Firebreak limiting its rate")
	battle.damage_enemy(1, 2800)
	_frames(battle, 1)
	_check(actor.phase_index == 1 and actor.hp == 5200 and actor.active_shield(battle.clock.tick) == 600, "Foreman phase grants temporary HP without changing its base HP")
	_check(is_equal_approx(battle.heat - before, 14.0 * 0.6 / 60.0), "Foreman phase adds a separate Heat output")
	battle.damage_enemy(1, 200)
	_check(actor.hp == 5200 and actor.active_shield(battle.clock.tick) == 400, "Temporary Foreman HP absorbs damage first")
	battle.clock.dialogue_open = true
	_frames(battle, 300)
	_check(actor.active_shield(battle.clock.tick) == 400, "Dialogue stops the temporary HP timer")
	battle.clock.dialogue_open = false
	_frames(battle, 300)
	battle.damage_enemy(1, 450)
	_check(actor.active_shield(battle.clock.tick) == 0 and actor.hp == 4750, "Foreman protection expires at five combat seconds")

func _leader_phases() -> void:
	var battle := _battle(LEADER)
	var clock := battle.clock
	var thresholds: Array[int] = []
	var reinforcement_ticks: Array[int] = []
	battle.boss_phase_changed.connect(func(_id: int, phase: BossPhase) -> void:
		thresholds.append(phase.hp_percent)
		clock.dialogue_open = true
	)
	battle.enemy_spawned.connect(func(_id: int, definition_id: StringName) -> void:
		if definition_id == &"E03":
			reinforcement_ticks.append(clock.tick)
	)
	_frames(battle, 1)
	var actor := battle.active[1]
	battle.damage_enemy(1, 9000)
	battle.clock.set_speed(2)
	_frames(battle, 1)
	_check(thresholds == [70] and battle.clock.tick == 2 and actor.phase_speed_scale == 1.0, "One hit crossing both thresholds presents the 70% Leader phase first")
	_frames(battle, 200)
	_check(thresholds == [70] and reinforcement_ticks.is_empty(), "Phase dialogue holds the next event and all arrivals")
	battle.clock.dialogue_open = false
	_frames(battle, 1)
	_check(thresholds == [70, 35] and battle.clock.tick == 3 and actor.phase_speed_scale == 1.5, "The next combat step presents the 35% Leader phase once")
	battle.clock.dialogue_open = false
	battle.clock.set_speed(1)
	var before := actor.distance
	_frames(battle, 1)
	_check(is_equal_approx(actor.distance - before, LEADER.tiles_per_second * 1.5 / 60.0), "Poacher Leader uses the final surge on the shared clock")
	battle.damage_enemy(1, 4000)
	_frames(battle, 118)
	_check(reinforcement_ticks == [62, 93, 122] and battle.active.size() == 3, "Two Leader phases queue three Runners at deterministic separate ticks")
	_check(battle.expected_enemy_count == 4 and battle.outcome == BattleSimulation.Outcome.RUNNING, "Leader defeat leaves the registered Runners in the victory condition")
	for id in battle.active.keys():
		battle.damage_enemy(id, battle.active[id].hp)
	_check(battle.is_perfect() and battle.defeated == 4, "The final Leader wave finishes after the last Runner")

func _sandbox_flow() -> void:
	root.size = Vector2i(960, 540)
	var sandbox := SANDBOX.instantiate()
	root.add_child(sandbox)
	await process_frame
	await process_frame
	var content := sandbox.get_node("%Content")
	var chooser: OptionButton = content.find_child("EncounterChoice", true, false)
	_check(chooser.item_count == 19 and chooser.selected == 0, "Sandbox presents the full roster and eighteen named encounters")
	chooser.select(12)
	chooser.item_selected.emit(12)
	content.find_child("StartEncounter", true, false).pressed.emit()
	var field := content.get_child(0) as BattleScene
	field.set_physics_process(false)
	_check(field.stage.enemy_count() == 1 and field.stage.waves[0].groups[0].enemy.enemy_id == &"E12" and not field.get_node("%DefeatEnemy").visible, "A standard selection launches its real scenario with practice hits hidden")
	field.get_node("%BackToMenu").pressed.emit()
	chooser = content.find_child("EncounterChoice", true, false)
	_check(chooser.selected == 12, "Returning from battle retains the selected enemy")
	chooser.select(16)
	chooser.item_selected.emit(16)
	content.find_child("StartEncounter", true, false).pressed.emit()
	field = content.get_child(0) as BattleScene
	field.set_physics_process(false)
	await process_frame
	await process_frame
	var battle := field.battle
	var practice: Button = field.get_node("%DefeatEnemy")
	var overlay: Control = field.get_node("%Dialogue")
	var board: Control = field.get_node("%Board")
	var tray: Control = field.get_node("%TrayScroll")
	_check(board.get_global_rect().end.y <= tray.get_global_rect().position.y and practice.disabled, "Small landscape keeps the trial tray separate and locks practice before spawn")
	_frames(battle, 361)
	_check(overlay.visible and battle.clock.dialogue_open and practice.disabled, "A sandbox boss intro pauses the scene with its controls unavailable")
	field.get_node("%Continue").pressed.emit()
	practice.pressed.emit()
	_check(battle.active[1].hp == 1750 and battle.active[1].phase_index == 0, "Practice hit applies actual damage up to the next authored threshold")
	field._physics_process(0.0)
	var tick := battle.clock.tick
	_frames(battle, 120)
	_check(overlay.visible and battle.clock.tick == tick and battle.expected_enemy_count == 3 and battle.active.size() == 1, "Phase dialogue holds the scheduled sandbox reinforcements")
	field.get_node("%Skip").pressed.emit()
	_frames(battle, 60)
	_check(battle.active[2].definition.enemy_id == &"E02", "Skipping phase dialogue resumes the scheduled arrival")
	practice.pressed.emit()
	_check(battle.captured_boss_id == CAPTAIN.enemy_id and field.get_node("%Status").text == "Boss captured", "The sandbox presents its real capture outcome")
	field.get_node("%BackToMenu").pressed.emit()
	_check(content.find_child("EncounterChoice", true, false).selected == 16, "Roster navigation keeps the chosen boss available for replay")
	sandbox.queue_free()

func _stage(boss: BossSpec, capture := false, heat := false) -> BattleStage:
	var stage := ARENA.duplicate() as BattleStage
	stage.stage_id = &"qa.boss_unit"
	stage.opening_delay_seconds = 7.0 if heat else 0.0
	stage.capture_boss_id = boss.enemy_id if capture else &""
	if not heat:
		stage.heat_capacity = 0.0
		stage.heat_integrity_loss = 0
	var group := BattleSpawnGroup.new()
	group.count = 1
	group.enemy = boss
	var wave := BattleWave.new()
	wave.groups = [group]
	stage.waves = [wave]
	return stage

func _battle(boss: BossSpec, capture := false, heat := false) -> BattleSimulation:
	var stage := _stage(boss, capture, heat)
	var battle := BattleSimulation.new(stage)
	battle.deployment = DeploymentState.new(stage.map, battle.clock, 500)
	return battle

func _frames(battle: BattleSimulation, count: int) -> void:
	for frame in count:
		battle.clock.advance_frame()

func _check(ok: bool, text: String) -> void:
	if ok:
		print("PASS ", text)
	else:
		printerr("FAIL ", text)
		_failed += 1
