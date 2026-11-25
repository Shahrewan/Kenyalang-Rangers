extends SceneTree

const STAGE := preload("res://tests/fixtures/c10_offense_stage.tres")
const ROSTER := preload("res://data/rangers/offense.tres")
const SCOUT: RangerSpec = preload("res://data/rangers/scout_sniper.tres")
const CROWD: RangerSpec = preload("res://data/rangers/crowd_controller.tres")
const GUARD: RangerSpec = preload("res://data/rangers/guard_veteran.tres")
const SANDBOX := preload("res://scenes/qa/ranger_sandbox.tscn")

var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_catalog()
	_scout_without_records()
	_scout_focus()
	_crowd_emp()
	_guard_charges()
	_emp_wave_completion()
	await _sandbox_touch()
	print("Offense Ranger checks complete. Failures: ", _failed)
	quit(0 if _failed == 0 else 1)

func _catalog() -> void:
	var ids: Array[StringName] = []
	for entry: RangerSpec in ROSTER.entries:
		ids.append(entry.id)
		_check(entry.ranger_class == RangerSpec.RangerClass.OFFENSE and entry.level == 1 and entry.footprint(Vector2i.ZERO).size() == 1, "%s loads as a one-cell Lv.1 Offense Ranger" % entry.label)
	_check(ids == [&"ranger.scout_sniper", &"ranger.crowd_controller", &"ranger.guard_veteran"], "Offense catalog uses the three approved IDs")
	_check(SCOUT.max_hp == 100 and CROWD.max_hp == 120 and GUARD.max_hp == 230, "Offense HP matches the GDD's provisional values")
	_check(STAGE.validation_error().is_empty() and STAGE.enemy_count() == 10, "Sandbox stage validates with two populated waves")

func _scout_without_records() -> void:
	var battle := _encounter()
	var state := battle.deployment
	_check(not state.deploy(SCOUT, Vector2i(2, 1), 1).is_empty() and state.tokens == 100, "Scout requires an elevated tile with no spend on an invalid drop")
	_check(state.deploy(SCOUT, Vector2i(2, 0), 1).is_empty() and state.tokens == 88, "Scout placement charges the 12-Token fixture cost")
	var scout := state.placed[SCOUT.id]
	var marked := _enemy(battle, 100, 1.0)
	var leading := _enemy(battle, 101, 3.0, false, true)
	marked.focus_marked_until = 121
	_check(not battle.tap_ranger(SCOUT.id) and state.armed.is_empty() and scout.skill_charges == 0, "An unenhanced Scout cannot arm or spend Focus")
	_frames(battle, 1)
	_check(marked.hp == 476 and leading.hp == 500 and scout.next_attack_tick == 121, "Unenhanced Scout prioritizes a marked target for 24 HP on a two-second cadence")
	_frames(battle, 120)
	_check(marked.hp == 476 and leading.hp == 476, "Expired priority gives way to the leading eligible Aerial enemy")

func _scout_focus() -> void:
	var battle := _encounter([SCOUT.records_enhancement])
	var state := battle.deployment
	state.deploy(SCOUT, Vector2i(2, 0), 1)
	var scout := state.placed[SCOUT.id]
	var chosen := _enemy(battle, 100, 1.0)
	var other := _enemy(battle, 101, 3.0)
	_check(battle.tap_ranger(SCOUT.id) and chosen.hp == 500 and state.armed == SCOUT.id, "Steady Aim arms Focus without applying damage")
	_check(not state.select_target(Vector2i(6, 3)) and not battle.confirm_ranger_target() and scout.skill_charges == 1, "An out-of-range Focus cannot be confirmed or spend a charge")
	state.select_target(Vector2i(0, 0))
	_check(not battle.confirm_ranger_target() and scout.skill_charges == 1 and state.armed == SCOUT.id, "An empty aim tile keeps the charge and allows another selection")
	state.select_target(chosen.grid_cell())
	battle.clock.dialogue_open = true
	_check(not battle.confirm_ranger_target() and chosen.hp == 500, "Full-screen dialogue prevents a committed Focus")
	battle.clock.dialogue_open = false
	_check(battle.confirm_ranger_target() and chosen.hp == 476 and other.hp == 500 and state.armed.is_empty(), "Confirm deals 24 HP to only the chosen enemy")
	_check(chosen.immobilized_until == 90 and chosen.focus_marked_until == 360 and scout.skill_charges == 0, "Focus applies independent immobilize and priority deadlines and spends its charge")
	_frames(battle, 1)
	_check(chosen.hp == 446 and other.hp == 500 and chosen.distance == 1.0, "Enhanced Scout deals 30 HP to its marked priority target while it is immobilized")
	battle.clock.paused = true
	_frames(battle, 1200)
	_check(battle.clock.tick == 1 and chosen.distance == 1.0 and scout.skill_charges == 0, "Pause holds Focus effects and its recharge")
	battle.clock.paused = false
	_frames(battle, 88)
	_check(chosen.distance == 1.0, "Immobilize holds up to the last tick before expiry")
	_frames(battle, 1)
	_check(chosen.distance > 1.0, "Movement resumes exactly when immobilize expires")
	_frames(battle, 629)
	_check(not battle.tap_ranger(SCOUT.id) and scout.skill_charges == 0, "Focus cannot be rearmed a tick early")
	_frames(battle, 1)
	_check(scout.skill_charges == 1, "Focus restores its charge after twelve combat seconds")

func _crowd_emp() -> void:
	var battle := _encounter()
	var state := battle.deployment
	state.deploy(CROWD, Vector2i(2, 2), 1)
	var crowd := state.placed[CROWD.id]
	_check(not battle.tap_ranger(CROWD.id) and crowd.skill_charges == 1, "An EMP attempt with no target leaves the charge available")
	var ground := _enemy(battle, 100, 2.0)
	var tech := _enemy(battle, 101, 3.0, true)
	var air := _enemy(battle, 102, 3.2, false, true)
	var outside := _enemy(battle, 103, 0.0)
	_frames(battle, 1)
	_check(ground.hp == 470 and tech.hp == 461 and air.hp == 470 and outside.hp == 500, "Basic EMP splashes eligible ground and air, applying its 30% bonus per Technological victim")
	_check(crowd.next_attack_tick == 181, "Basic EMP repeats after three combat seconds")
	_check(battle.tap_ranger(CROWD.id) and ground.hp == 420 and tech.hp == 411 and air.hp == 420 and outside.hp == 500, "Empowered EMP applies its 50 HP splash once")
	_check(battle.ranger_combat.fields.size() == 1 and battle.ranger_combat.fields[0].area.size == Vector2i(3, 3) and crowd.skill_charges == 0, "Empowered EMP creates a three-by-three field and spends its charge")
	_check(not battle.tap_ranger(CROWD.id) and ground.hp == 420, "A second tap during recharge applies no damage")
	var late := _enemy(battle, 104, 2.6)
	var before := tech.distance
	var outside_before := outside.distance
	battle.clock.set_speed(2)
	battle.clock.dialogue_open = true
	_frames(battle, 120)
	_check(battle.clock.tick == 1 and tech.distance == before and battle.ranger_combat.fields.size() == 1, "Dialogue holds the EMP field and movement even at two times speed")
	battle.clock.dialogue_open = false
	_frames(battle, 1)
	_check(is_equal_approx(tech.distance - before, CombatClock.STEP_SECONDS * 0.5) and is_equal_approx(outside.distance - outside_before, CombatClock.STEP_SECONDS), "Two combat ticks apply the 50% field slow only inside its square")
	_check(late.hp == 500 and is_equal_approx(late.distance - 2.6, CombatClock.STEP_SECONDS * 0.5), "Later field entrants slow without taking the initial splash")
	battle.clock.set_speed(1)
	_frames(battle, 237)
	_check(battle.ranger_combat.fields.size() == 1, "EMP field stays for four combat seconds")
	_frames(battle, 1)
	_check(battle.ranger_combat.fields.is_empty() and crowd.skill_charges == 0, "EMP slow expires separately from the recharge")
	_frames(battle, 660)
	_check(crowd.skill_charges == 1, "Empowered EMP recharges after fifteen combat seconds")

func _guard_charges() -> void:
	var battle := _encounter()
	var state := battle.deployment
	var anchor := Vector2i(3, 1)
	_check(not state.deploy(GUARD, Vector2i(2, 0), 1).is_empty() and state.tokens == 100, "Guard requires ground and preserves Tokens on an invalid drop")
	state.deploy(GUARD, anchor, -1)
	var guard := state.placed[GUARD.id]
	_check(guard.skill_charges == 4 and guard.facing == -1 and state.coverage(GUARD, anchor, guard.facing) == [Vector2i(2, 1), Vector2i(1, 1)], "Guard deploys with four charges and two fixed front tiles")
	_check(not battle.tap_ranger(GUARD.id) and guard.skill_charges == 4, "Guard does not spend a charge against an empty front")
	var blocked := _enemy(battle, 100, 2.49)
	var passing := _enemy(battle, 101, 2.487)
	var near := _enemy(battle, 102, 1.0)
	var rear := _enemy(battle, 103, 4.2)
	var air := _enemy(battle, 104, 2.49, false, true)
	_frames(battle, 1)
	_check(blocked.blocked_by == GUARD.id and passing.blocked_by.is_empty() and air.blocked_by.is_empty(), "Guard blocks one ground enemy while the next ground enemy and Aerial can pass")
	_check(blocked.hp == 468 and near.hp == 468 and rear.hp == 500 and air.hp == 500 and guard.next_attack_tick == 121, "Guard basic deals 32 to both front tiles and excludes rear and Aerial")
	_frames(battle, 99)
	for charge in range(4):
		_check(battle.tap_ranger(GUARD.id) and guard.skill_charges == 3 - charge, "Guard can use charge %d out of four" % (charge + 1))
	_check(not battle.tap_ranger(GUARD.id) and blocked.hp == 284 and near.hp == 284 and rear.hp == 500 and air.hp == 500, "Each Guard charge deals 46 frontal HP and a fifth tap deals none")
	_check(guard.next_attack_tick == 220 and guard.skill_recharge_tick == 880 and near.stunned_until == 160, "Guard charge resets the basic swing and starts one sequential recharge deadline")
	var held := near.distance
	_frames(battle, 59)
	_check(near.distance == held and guard.hp == 230, "Stun prevents both movement and a blocked enemy's due attack")
	_frames(battle, 1)
	_check(near.distance > held and guard.hp == 224, "Stun expires and both movement and combat resume")
	_frames(battle, 59)
	_check(blocked.hp == 284, "Guard skips the previously scheduled basic swing")
	_frames(battle, 1)
	_check(blocked.hp == 252, "Guard basic swing resumes at the reset deadline")
	battle.clock.paused = true
	_frames(battle, 780)
	_check(battle.clock.tick == 220 and guard.skill_charges == 0, "Paused time cannot replenish Guard charges")
	battle.clock.paused = false
	_frames(battle, 659)
	_check(guard.skill_charges == 0, "Guard charges stay empty one tick before recharge")
	_frames(battle, 1)
	_check(guard.skill_charges == 1 and guard.skill_recharge_tick == 1660, "Guard restores exactly one charge at thirteen combat seconds")
	battle.clock.set_speed(2)
	_frames(battle, 390)
	_check(guard.skill_charges == 2 and battle.clock.tick == 1660, "The next Guard charge restores separately at two times speed")
	_check(state.retreat(GUARD.id) and state.cooldown_ticks(GUARD.id) == CombatClock.ticks_for(GUARD.redeploy_seconds) and not state.occupancy.has(anchor), "Guard retreat frees its tile and starts combat-time redeploy cooldown")
	var funds := state.tokens
	_check(not state.deploy(GUARD, anchor, 1).is_empty() and state.tokens == funds, "A cooldown drop preserves Tokens")
	_frames(battle, ceili(CombatClock.ticks_for(GUARD.redeploy_seconds) / 2.0))
	_check(state.deploy(GUARD, anchor, 1).is_empty() and state.placed[state.interaction_id(anchor)].facing == 1 and state.placed[state.interaction_id(anchor)].skill_charges == 4, "Redeploy after cooldown makes a fresh Guard placement with chosen facing")

func _emp_wave_completion() -> void:
	var stage := STAGE.duplicate() as BattleStage
	stage.opening_delay_seconds = 0.0
	var enemy := BattleEnemyDefinition.new()
	enemy.max_hp = 50
	enemy.tiles_per_second = 0.5
	var group := BattleSpawnGroup.new()
	group.enemy = enemy
	group.count = 2
	var wave := BattleWave.new()
	wave.groups = [group]
	stage.waves = [wave]
	var battle := BattleSimulation.new(stage)
	battle.deployment = DeploymentState.new(stage.map, battle.clock, 100)
	_frames(battle, 2)
	battle.deployment.deploy(CROWD, Vector2i(1, 2), 1)
	_check(battle.tap_ranger(CROWD.id) and battle.defeated == 2 and battle.is_perfect(), "One EMP can resolve two registered enemies and finish the wave as a perfect clear")
	_check(not battle.tap_ranger(CROWD.id) and battle.defeated == 2 and battle.clock.stopped, "A stopped battle cannot apply the final EMP twice")

func _sandbox_touch() -> void:
	root.size = Vector2i(960, 540)
	var sandbox := SANDBOX.instantiate()
	root.add_child(sandbox)
	var scene := sandbox.get_node("SafeArea/Field") as BattleScene
	scene.set_physics_process(false)
	await process_frame
	await process_frame
	var battle := scene.battle
	var state := battle.deployment
	var tray: HBoxContainer = scene.get_node("%DeploymentTray")
	var board: BattleBoard = scene.get_node("%Board")
	_check(tray.get_child_count() == 3 and state.tokens == 100 and not scene.get_node("%DefeatEnemy").visible, "Sandbox loads the three real Ranger cards and a private trial budget")
	_drag(tray.get_child(0).get_global_rect().get_center(), _at(board, Vector2i(2, 0)))
	_drag(tray.get_child(1).get_global_rect().get_center(), _at(board, Vector2i(2, 2)))
	_drag(tray.get_child(2).get_global_rect().get_center(), _at(board, Vector2i(3, 1), -16.0))
	scene.find_child("FaceLeft", true, false).pressed.emit()
	scene.find_child("ConfirmDeploy", true, false).pressed.emit()
	_check(state.placed.size() == 3 and state.tokens == 54 and state.placed[GUARD.id].facing == -1, "Synthetic touch deploys the Offense roster with the chosen Guard facing")
	_frames(battle, 824)
	var enemy := battle.active[1]
	var hp := enemy.hp
	var aim := _at(board, enemy.grid_cell())
	_tap(_at(board, Vector2i(2, 0)))
	_check(state.armed == SCOUT.id and scene.get_node("%ConfirmSkill").visible, "Tapping the enhanced Scout offers a real confirmation control")
	_drag(aim, aim + Vector2(24, 0))
	_check(enemy.hp == hp and state.pending_target == DeploymentState.NO_CELL, "An unconfirmed target drag leaves the enemy and Focus charge untouched")
	_tap(aim)
	_check(enemy.hp == hp and state.pending_target == enemy.grid_cell(), "A target tap selects the cell without firing")
	scene.get_node("%ConfirmSkill").pressed.emit()
	_check(enemy.hp == hp - 24 and enemy.immobilized_until > battle.clock.tick, "Sandbox confirmation commits the Scout's actual damage and status")
	scene.get_node("%Pause").pressed.emit()
	var tick := battle.clock.tick
	_frames(battle, 180)
	_check(scene.get_node("%PauseOverlay").visible and battle.clock.tick == tick, "Sandbox pause holds the live roster and enemies")
	scene.get_node("%Retry").pressed.emit()
	_check(scene.battle.active.is_empty() and scene.battle.deployment.placed.is_empty() and scene.battle.deployment.tokens == 100, "Restart returns the sandbox to a fresh encounter")
	sandbox.queue_free()

func _encounter(enhancements: Array[StringName] = []) -> BattleSimulation:
	var stage := STAGE.duplicate() as BattleStage
	stage.opening_delay_seconds = 120.0
	var battle := BattleSimulation.new(stage)
	battle.deployment = DeploymentState.new(stage.map, battle.clock, 100, null, enhancements)
	return battle

func _enemy(battle: BattleSimulation, id: int, distance: float, technological := false, aerial := false) -> BattleEnemy:
	var definition := BattleEnemyDefinition.new()
	definition.max_hp = 500
	definition.tiles_per_second = 0.5
	definition.technological = technological
	definition.aerial = aerial
	var enemy := BattleEnemy.new(definition, STAGE.routes[0])
	enemy.distance = distance
	battle.active[id] = enemy
	return enemy

func _frames(battle: BattleSimulation, count: int) -> void:
	for frame in count:
		battle.clock.advance_frame()

func _at(board: BattleBoard, cell: Vector2i, offset_x := 0.0) -> Vector2:
	return board.get_global_transform_with_canvas() * (board.cell_center(cell) + Vector2(offset_x, 0))

func _touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	root.push_input(event, true)

func _tap(position: Vector2) -> void:
	_touch(position, true)
	_touch(position, false)

func _drag(from: Vector2, to: Vector2) -> void:
	_touch(from, true)
	var drag := InputEventScreenDrag.new()
	drag.position = to
	drag.relative = to - from
	root.push_input(drag, true)
	_touch(to, false)

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		printerr("FAIL ", label)
		_failed += 1
