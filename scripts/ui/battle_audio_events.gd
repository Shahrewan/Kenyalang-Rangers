class_name BattleAudioEvents
extends RefCounted

const RANGER_ATTACKS := {
	&"ranger.scout_sniper": "ranger_scout_sniper_attack",
	&"ranger.barricade_ops": "ranger_guard_attack",
	&"ranger.guard_veteran": "ranger_guard_attack",
	&"ranger.k9_ranger": "ranger_k9_ranger_attack",
	&"ranger.outpost_mechanic": "ranger_outpost_mechanic_attack",
	&"ranger.kenyalang_seer": "ranger_kenyalang_seer_attack",
	&"ranger.crowd_controller": "ranger_crowd_controller_attack",
}
const SKILLS := {
	&"ranger.scout_sniper": "ranger_scout_sniper_focus",
	&"ranger.combat_medic": "ranger_combat_medic_treatment",
	&"ranger.guard_veteran": "ranger_guard_veteran_stun_prod",
	&"ranger.k9_ranger": "ranger_k9_ranger_howl",
	&"ranger.kenyalang_seer": "ranger_kenyalang_seer_scan",
	&"ranger.crowd_controller": "ranger_crowd_controller_emp",
	&"facility.medic_cabin": "facility_medic_cabin_kit",
	&"facility.specialist_calltower": "facility_specialist_calltower_claim",
}
const ABILITIES := {
	&"E03": "enemy_e03_sprint", &"E06": "enemy_e06_smoke", &"E07": "enemy_e07_jam",
	&"E09": "enemy_e09_track", &"E10": "enemy_e10_net", &"E13": "enemy_e13_breach",
}
const ENEMY_ATTACKS := {
	&"E04": "enemy_melee_heavy", &"E05": "enemy_e05_attack", &"E08": "enemy_e08_attack",
	&"E11": "enemy_e11_siege", &"E12": "enemy_e12_siege", &"E13": "enemy_melee_heavy",
	&"E15": "enemy_melee_heavy", &"boss.illegal_logging_foreman": "boss_illegal_logging_foreman_attack",
	&"boss.diversion_captain": "enemy_melee_heavy", &"boss.poacher_leader": "enemy_melee_heavy",
}

var _battle: BattleSimulation
var _state: DeploymentState
var _play: Callable
var _spawn_wave := 0
var _priority_wave := 0

func _init(battle: BattleSimulation, placement: DeploymentState, play: Callable) -> void:
	_battle = battle
	_state = placement
	_play = play
	battle.enemy_spawned.connect(_spawned)
	battle.enemy_outcome_presented.connect(_enemy_outcome)
	battle.enemy_attack_presented.connect(_enemy_attack)
	battle.enemy_ability_presented.connect(_enemy_ability)
	battle.block_contact_presented.connect(_emit.bind("combat_block_contact"))
	battle.siege_windup_presented.connect(_emit.bind("combat_siege_telegraph"))
	battle.wave_resolved.connect(_wave_resolved)
	battle.boss_intro.connect(_boss_intro)
	battle.boss_phase_changed.connect(_boss_phase)
	battle.boss_captured.connect(_boss_captured)
	battle.cinematic_withdrawal.connect(_emit.bind("combat_messenger_withdrawal"))
	battle.ranger_combat.attack_presented.connect(_ranger_attack)
	battle.ranger_combat.healing_presented.connect(_heal)
	battle.ranger_combat.kit_presented.connect(_field_kit)
	battle.facility_combat.sonic_attack_presented.connect(_sonic)
	battle.facility_combat.action_presented.connect(_facility_action)
	battle.facility_combat.repair_presented.connect(_repair)
	placement.unit_deployed.connect(_deployed)
	placement.ranger_committed.connect(_ranger_committed)
	placement.unit_removed.connect(_removed)
	placement.ranger_withdrew.connect(_withdrew)
	placement.construction_ready_presented.connect(_emit.bind("facility_construction_ready"))
	placement.construction_cancelled_presented.connect(_emit.bind("facility_construction_cancel"))
	placement.tokens_produced.connect(_emit.bind("combat_tokens"))
	placement.skill_ready_presented.connect(_emit.bind("combat_skill_ready"))
	placement.skill_fired.connect(_skill)

func _emit(cue: String) -> void:
	_play.call(cue)

func _deployed(unit: DeploymentState.Placement) -> void:
	if unit.ranger == null:
		_emit("facility_construction_start" if unit.build_deadline > _battle.clock.tick else "combat_deploy")

func _ranger_committed(unit: DeploymentState.Placement) -> void:
	# The simulation handles Ranger placement before this listener. A successful net already landed.
	if unit.net_landed:
		_emit("ranger_woods_tracker_net")
	elif not unit.mount_tower.is_empty():
		_emit("facility_sentry_tower_mount")
	else:
		_emit("combat_deploy")

func _skill(id: StringName, _target: Vector2i) -> void:
	var unit: DeploymentState.Placement = _state.placed.get(id)
	if unit != null:
		_emit(SKILLS.get(unit.spec.id, "combat_skill"))

func _removed(unit: DeploymentState.Placement) -> void:
	if unit.hp <= 0:
		_emit("combat_ranger_down" if unit.spec.is_ranger() else "combat_facility_destroyed")

func _withdrew(unit: DeploymentState.Placement) -> void:
	_emit("ranger_saboteurist_emp_retreat" if unit.spec.id == &"ranger.saboteurist" else "combat_retreat")

func _ranger_attack(unit: DeploymentState.Placement, _target: int, clip: StringName) -> void:
	if clip == &"Attack":
		_emit(RANGER_ATTACKS.get(unit.spec.id, "ranger_melee_attack"))

func _heal(_unit: DeploymentState.Placement, _target: Vector2i) -> void:
	_emit("ranger_combat_medic_heal")

func _repair(_unit: DeploymentState.Placement, _target: Vector2i) -> void:
	_emit("ranger_outpost_mechanic_repair")

func _field_kit(_unit: DeploymentState.Placement, _cell: Vector2, cue: String) -> void:
	if cue in ["strike_landed", "strike_arrival"]:
		_emit("ranger_strike_team_arrival")

func _sonic(_unit: DeploymentState.Placement) -> void:
	_emit("facility_sonic_turret_attack")

func _facility_action(unit: DeploymentState.Placement, _cell: Vector2, cue: String) -> void:
	if cue != "enemy_shot":
		return
	if unit.facility.role == FacilitySpec.Role.CANOPY_LAUNCHER:
		_emit("facility_canopy_defense_launcher_attack")
	elif unit.facility.role == FacilitySpec.Role.ELECTRIC_TURRET and unit.burst_remaining == maxi(1, unit.facility.burst_hits):
		_emit("facility_electric_pulse_turret_attack")

func _enemy_attack(enemy: BattleEnemy) -> void:
	var fallback := "enemy_melee_light"
	if enemy.definition.attack_profile != null:
		fallback = "combat_siege_warning" if enemy.definition.attack_profile.kind == EnemyAttackProfile.Kind.SIEGE else "enemy_ranged_light"
	_emit(ENEMY_ATTACKS.get(enemy.definition.enemy_id, fallback))

func _enemy_ability(enemy: BattleEnemy, _target: Vector2i) -> void:
	if enemy.definition.enemy_id == &"E13":
		var unit: DeploymentState.Placement = _state.placed.get(enemy.blocked_by)
		if unit == null or unit.knocked_down_until <= _battle.clock.tick:
			return
	_emit(ABILITIES.get(enemy.definition.enemy_id, ""))

func _spawned(serial: int, id: StringName) -> void:
	var enemy: BattleEnemy = _battle.active.get(serial)
	if enemy == null or enemy.reinforcement:
		return
	if _spawn_wave != _battle.wave_number:
		_spawn_wave = _battle.wave_number
		_emit("combat_wave_start")
	if id == &"E15" and _priority_wave != _battle.wave_number:
		_priority_wave = _battle.wave_number
		_emit("enemy_e15_priority_warning")

func _wave_resolved(completed: int) -> void:
	if completed < _battle.wave_count and _battle.clock.is_running():
		_emit("combat_wave_rest")

func _enemy_outcome(enemy: BattleEnemy, escaped: bool, integrity_lost: bool) -> void:
	var id := enemy.definition.enemy_id
	if escaped:
		if integrity_lost:
			_emit("combat_fatal_escape" if _battle.fatal_escape_id == id else "combat_integrity_loss")
	elif id == &"boss.poacher_leader":
		_emit("boss_poacher_leader_defeated")
	elif enemy.boss == null and enemy.definition.danger >= 4:
		_emit("combat_enemy_resolved")

func _boss_captured(_serial: int) -> void:
	_emit("boss_diversion_captain_capture")

func _boss_intro(_serial: int, boss: BossSpec) -> void:
	_emit(PresentationAudio.entity_cue(boss.enemy_id, "intro", "combat_boss_alert"))

func _boss_phase(serial: int, phase: BossPhase) -> void:
	var enemy: BattleEnemy = _battle.active.get(serial)
	if enemy == null:
		return
	match enemy.definition.enemy_id:
		&"boss.diversion_captain": _emit("boss_diversion_captain_phase")
		&"boss.illegal_logging_foreman": _emit("boss_illegal_logging_foreman_phase")
		&"boss.poacher_leader":
			_emit("boss_poacher_leader_phase_call" if phase.hp_percent == 70 else "boss_poacher_leader_phase_surge")
		_: _emit("combat_boss_alert")
