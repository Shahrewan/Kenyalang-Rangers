class_name EnemyAbilities
extends RefCounted

func advance(enemy: BattleEnemy, deployment: DeploymentState, facilities: FacilityCombat, tick: int) -> void:
	var ability := enemy.definition.ability
	if ability == null or tick < enemy.stunned_until:
		return
	if enemy.ability_fire_tick > 0:
		if tick >= enemy.ability_fire_tick:
			var target: DeploymentState.Placement
			if deployment != null:
				target = deployment.placed.get(enemy.ability_target)
			if ability.targets_self() or (target == enemy.ability_placement and _can_target(enemy, ability, enemy.ability_target, target)):
				_apply(enemy, ability, deployment, enemy.ability_target, target, tick)
			_finish(enemy, ability, tick)
		return
	if tick < enemy.ability_ready_tick:
		return

	var id: StringName
	var target: DeploymentState.Placement
	if not ability.targets_self():
		if deployment == null:
			return
		id = _select_target(enemy, ability, deployment)
		if id.is_empty():
			return
		target = deployment.placed[id]
	var windup := CombatClock.ticks_for(ability.windup_seconds)
	if ability.disruptible and deployment != null:
		windup += facilities.ability_delay(deployment, enemy.grid_cell(), tick)
	if windup > 0:
		enemy.ability_target = id
		enemy.ability_placement = target
		enemy.ability_fire_tick = tick + windup
	else:
		_apply(enemy, ability, deployment, id, target, tick)
		_finish(enemy, ability, tick)

func _select_target(enemy: BattleEnemy, ability: EnemyAbility, deployment: DeploymentState) -> StringName:
	if ability.effect == EnemyAbility.Effect.KNOCKDOWN:
		var id := enemy.blocked_by
		return id if _can_target(enemy, ability, id, deployment.placed.get(id)) else &""
	var chosen: StringName
	var nearest := ability.radius + 1
	for id: StringName in deployment.placed:
		var unit := deployment.placed[id]
		if _can_target(enemy, ability, id, unit):
			var distance := unit.distance_to(enemy.grid_cell())
			if distance < nearest:
				nearest = distance
				chosen = id
	return chosen

func _can_target(enemy: BattleEnemy, ability: EnemyAbility, id: StringName, unit: DeploymentState.Placement) -> bool:
	if unit == null or not unit.spec.is_ranger() or unit.distance_to(enemy.grid_cell()) > ability.radius:
		return false
	if ability.effect == EnemyAbility.Effect.JAM:
		return unit.spec.skill != DeploymentSpec.Skill.NONE
	if ability.effect == EnemyAbility.Effect.KNOCKDOWN:
		return enemy.blocked_by == id
	return true

func _apply(enemy: BattleEnemy, ability: EnemyAbility, deployment: DeploymentState, id: StringName, unit: DeploymentState.Placement, tick: int) -> void:
	var until := tick + CombatClock.ticks_for(ability.duration_seconds)
	match ability.effect:
		EnemyAbility.Effect.SPRINT:
			enemy.sprint_until = until
		EnemyAbility.Effect.SMOKE:
			enemy.smoke_until = until
		EnemyAbility.Effect.JAM:
			unit.jammed_until = maxi(unit.jammed_until, until)
			if unit.skill_recharge_tick > tick:
				unit.skill_recharge_tick += CombatClock.ticks_for(ability.skill_delay_seconds)
			_interrupt(deployment, id)
		EnemyAbility.Effect.TRACK:
			unit.attack_slow_until = maxi(unit.attack_slow_until, until)
			unit.attack_rate_scale = ability.ranger_attack_rate
		EnemyAbility.Effect.NET:
			unit.entangled_until = maxi(unit.entangled_until, until)
			_interrupt(deployment, id)
		EnemyAbility.Effect.KNOCKDOWN:
			if unit.spec.id != &"ranger.barricade_ops":
				unit.knocked_down_until = maxi(unit.knocked_down_until, until)
				_interrupt(deployment, id)

func _interrupt(deployment: DeploymentState, id: StringName) -> void:
	if deployment.armed == id:
		deployment.cancel_skill()

func _finish(enemy: BattleEnemy, ability: EnemyAbility, tick: int) -> void:
	var interval := maxi(1, CombatClock.ticks_for(ability.repeat_seconds))
	enemy.ability_ready_tick = tick + interval
	enemy.ability_fire_tick = 0
	enemy.ability_target = &""
	enemy.ability_placement = null
