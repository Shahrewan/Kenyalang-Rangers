class_name EnemyCombat
extends RefCounted

signal hit(enemy: BattleEnemy, target: StringName, kind: EnemyAttackProfile.Kind)

func advance(enemy: BattleEnemy, deployment: DeploymentState, facilities: FacilityCombat, tick: int) -> void:
	var profile := enemy.definition.attack_profile
	if profile == null or tick < enemy.stunned_until:
		return
	if not enemy.aim_target.is_empty():
		if tick >= enemy.fire_tick:
			var target: DeploymentState.Placement = deployment.placed.get(enemy.aim_target)
			if target == enemy.aim_placement and _distance_to(enemy.grid_cell(), target, profile) <= profile.radius:
				_hit(enemy, enemy.aim_target, tick)
			else:
				_finish_attack(enemy, tick)
		return
	if tick < enemy.profile_ready_tick:
		return

	var best: StringName
	var nearest := profile.radius + 1
	for id: StringName in deployment.placed:
		var distance := _distance_to(enemy.grid_cell(), deployment.placed[id], profile)
		if distance < nearest:
			nearest = distance
			best = id
	if best.is_empty():
		return
	var windup := CombatClock.ticks_for(profile.windup_seconds)
	if profile.disruptible:
		windup += facilities.ability_delay(deployment, enemy.grid_cell(), tick)
	if windup > 0:
		enemy.aim_target = best
		enemy.aim_placement = deployment.placed[best]
		enemy.fire_tick = tick + windup
	else:
		_hit(enemy, best, tick)

func _distance_to(cell: Vector2i, unit: DeploymentState.Placement, profile: EnemyAttackProfile) -> int:
	if unit != null and DeploymentState.accepts_hit(unit.spec, profile.kind):
		return unit.distance_to(cell)
	return profile.radius + 1

func _hit(enemy: BattleEnemy, target: StringName, tick: int) -> void:
	hit.emit(enemy, target, enemy.definition.attack_profile.kind)
	_finish_attack(enemy, tick)

func _finish_attack(enemy: BattleEnemy, tick: int) -> void:
	enemy.aim_target = &""
	enemy.aim_placement = null
	enemy.profile_ready_tick = tick + maxi(1, CombatClock.ticks_for(enemy.definition.attack_seconds))
