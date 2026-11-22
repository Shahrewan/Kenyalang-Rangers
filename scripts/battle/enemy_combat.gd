class_name EnemyCombat
extends RefCounted

func advance(enemy: BattleEnemy, deployment: DeploymentState, tick: int) -> void:
	var profile := enemy.definition.attack_profile
	if profile == null or tick < enemy.stunned_until:
		return
	if not enemy.aim_target.is_empty():
		if tick >= enemy.fire_tick:
			var target: DeploymentState.Placement = deployment.placed.get(enemy.aim_target)
			if _distance_to(enemy.grid_cell(), target, profile) <= profile.radius:
				_hit(enemy, deployment, enemy.aim_target, tick)
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
	if profile.windup_seconds > 0.0:
		enemy.aim_target = best
		enemy.fire_tick = tick + CombatClock.ticks_for(profile.windup_seconds)
	else:
		_hit(enemy, deployment, best, tick)

func _distance_to(cell: Vector2i, unit: DeploymentState.Placement, profile: EnemyAttackProfile) -> int:
	var nearest := profile.radius + 1
	if unit != null and DeploymentState.accepts_hit(unit.spec, profile.kind):
		for tile in unit.spec.footprint(unit.anchor):
			var delta := (tile - cell).abs()
			nearest = mini(nearest, maxi(delta.x, delta.y))
	return nearest

func _hit(enemy: BattleEnemy, deployment: DeploymentState, target: StringName, tick: int) -> void:
	deployment.receive_hit(target, enemy.definition.attack_damage, enemy.definition.attack_profile.kind)
	_finish_attack(enemy, tick)

func _finish_attack(enemy: BattleEnemy, tick: int) -> void:
	enemy.aim_target = &""
	enemy.profile_ready_tick = tick + maxi(1, CombatClock.ticks_for(enemy.definition.attack_seconds))
