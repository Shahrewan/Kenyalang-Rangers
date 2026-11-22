class_name FacilityCombat
extends RefCounted

signal hit(enemy_id: int, damage: int)

var _enemies: Dictionary[int, BattleEnemy]

func _init(enemies: Dictionary[int, BattleEnemy]) -> void:
	_enemies = enemies

func advance(deployment: DeploymentState, tick: int) -> void:
	for unit: DeploymentState.Placement in deployment.placed.values():
		if not deployment.clock.is_running():
			return
		if unit.facility != null and tick >= unit.build_deadline:
			if unit.facility.category == FacilitySpec.Category.SENTRY:
				_fire_turret(unit, deployment, tick)
			elif unit.facility.work_seconds > 0.0 and tick >= unit.next_utility_tick:
				_resource_pulse(unit, deployment, tick)
		elif unit.ranger != null and unit.ranger.repair_hp > 0 and tick >= unit.next_utility_tick:
			_repair(unit, deployment, tick)

func use_skill(unit: DeploymentState.Placement, target: Vector2i, deployment: DeploymentState) -> String:
	if unit.facility.role == FacilitySpec.Role.SPECIALIST_CALLTOWER:
		return "" if deployment.claim_specialist_discount(unit.facility.discount_tokens) else "A Specialist discount is already ready."
	var target_id := deployment.interaction_id(target)
	if deployment.heal_ranger(target_id, unit.facility.heal_per_kit) == 0:
		return "Choose an injured Ranger for the kit."
	return ""

func _resource_pulse(unit: DeploymentState.Placement, deployment: DeploymentState, tick: int) -> void:
	var spec := unit.facility
	unit.next_utility_tick = tick + maxi(1, CombatClock.ticks_for(spec.work_seconds))
	var reduction := CombatClock.ticks_for(spec.cooldown_reduction_seconds)
	match spec.role:
		FacilitySpec.Role.MEDIC_CABIN, FacilitySpec.Role.SPECIALIST_CALLTOWER:
			unit.stock = mini(spec.stock_capacity, unit.stock + 1)
		FacilitySpec.Role.SKILL_RELAY:
			for ally: DeploymentState.Placement in deployment.placed.values():
				if ally.skill_recharge_tick > tick and _in_reach(unit.anchor, spec.attack_range, ally):
					ally.skill_recharge_tick = maxi(tick, ally.skill_recharge_tick - reduction)
					ally.recharge_skill(tick)
		FacilitySpec.Role.DISPATCH_RELAY:
			deployment.reduce_deployment_cooldowns(reduction)

func update_detection(deployment: DeploymentState, tick: int) -> void:
	for enemy: BattleEnemy in _enemies.values():
		if not enemy.definition.concealed:
			continue
		enemy.tower_detected = false
		var cell := enemy.grid_cell()
		for unit: DeploymentState.Placement in deployment.placed.values():
			if unit.facility == null or tick < unit.build_deadline or unit.facility.role != FacilitySpec.Role.SENTRY_TOWER:
				continue
			var delta := (cell - unit.anchor).abs()
			if maxi(delta.x, delta.y) <= unit.facility.detection_radius:
				enemy.tower_detected = true
				break

func heat_multiplier(deployment: DeploymentState, tick: int) -> float:
	var strongest := 0
	for unit: DeploymentState.Placement in deployment.placed.values():
		if unit.facility != null and tick >= unit.build_deadline and unit.facility.role == FacilitySpec.Role.FIREBREAK:
			strongest = maxi(strongest, unit.facility.heat_slow_percent)
	return maxf(0.01, (100 - strongest) / 100.0)

func attack_interval(deployment: DeploymentState, unit: DeploymentState.Placement, tick: int) -> int:
	var base := CombatClock.ticks_for(unit.spec.attack_seconds)
	var hub := _zone(deployment, FacilitySpec.Role.COORDINATION_HUB, unit.spec.footprint(unit.anchor), tick)
	if hub == null:
		return maxi(1, base)
	return maxi(1, ceili(base * 100.0 / (100 + maxi(0, hub.attack_rate_bonus_percent))))

func enemy_damage(deployment: DeploymentState, enemy: BattleEnemy, target: DeploymentState.Placement, tick: int) -> int:
	var disrupt := _zone(deployment, FacilitySpec.Role.DISRUPTION, [enemy.grid_cell()], tick)
	var cover := _zone(deployment, FacilitySpec.Role.REINFORCED_COVER, target.spec.footprint(target.anchor), tick)
	var factor := 1.0
	if disrupt != null:
		factor *= clampf(1.0 - disrupt.outgoing_reduction_percent / 100.0, 0.0, 1.0)
	if cover != null:
		factor *= clampf(1.0 - cover.incoming_reduction_percent / 100.0, 0.0, 1.0)
	return roundi(enemy.definition.attack_damage * factor)

func ability_delay(deployment: DeploymentState, cell: Vector2i, tick: int) -> int:
	var disrupt := _zone(deployment, FacilitySpec.Role.DISRUPTION, [cell], tick)
	return maxi(0, CombatClock.ticks_for(disrupt.ability_delay_seconds)) if disrupt != null else 0

func _zone(deployment: DeploymentState, role: FacilitySpec.Role, cells: Array[Vector2i], tick: int) -> FacilitySpec:
	for unit: DeploymentState.Placement in deployment.placed.values():
		var spec := unit.facility
		if spec == null or spec.role != role or tick < unit.build_deadline:
			continue
		for cell in cells:
			var delta := (cell - unit.anchor).abs()
			if maxi(delta.x, delta.y) <= spec.attack_range:
				return spec
	return null

func _repair(unit: DeploymentState.Placement, deployment: DeploymentState, tick: int) -> void:
	var target: StringName
	var most_missing := 0
	for id: StringName in deployment.placed:
		var ally := deployment.placed[id]
		var missing := ally.spec.max_hp - ally.hp
		if missing > most_missing and DeploymentState.accepts_repair(ally.spec) and _in_reach(unit.anchor, unit.ranger.repair_range, ally):
			most_missing = missing
			target = id
	if not target.is_empty():
		deployment.repair(target, unit.ranger.repair_hp)
		unit.next_utility_tick = tick + maxi(1, CombatClock.ticks_for(unit.ranger.repair_seconds))

func _fire_turret(unit: DeploymentState.Placement, deployment: DeploymentState, tick: int) -> void:
	if tick < unit.next_attack_tick:
		return
	var spec := unit.facility
	var targets := _turret_targets(unit, deployment)
	if spec.role == FacilitySpec.Role.ELECTRIC_TURRET:
		_electric_shot(unit, targets, tick)
		return
	if targets.is_empty():
		return
	unit.next_attack_tick = tick + maxi(1, CombatClock.ticks_for(spec.attack_seconds))
	if spec.role == FacilitySpec.Role.SONIC_TURRET:
		for id in targets:
			var enemy := _enemies[id]
			enemy.sonic_slow_until = tick + CombatClock.ticks_for(spec.slow_seconds)
			enemy.sonic_speed_scale = spec.slow_speed_scale
			hit.emit(id, spec.attack_damage)
	elif spec.role == FacilitySpec.Role.CANOPY_LAUNCHER:
		var center := _enemies[_leading_target(targets, true)].grid_cell()
		for id in targets:
			var enemy := _enemies[id]
			var delta := (enemy.grid_cell() - center).abs()
			if maxi(delta.x, delta.y) <= spec.splash_radius:
				var scale := 1.0 if enemy.definition.aerial else spec.ground_damage_scale
				hit.emit(id, roundi(spec.attack_damage * scale))

func _electric_shot(unit: DeploymentState.Placement, targets: Array[int], tick: int) -> void:
	var spec := unit.facility
	if unit.burst_remaining == 0:
		if targets.is_empty():
			return
		unit.burst_remaining = maxi(1, spec.burst_hits)
	if unit.burst_target not in targets:
		unit.burst_target = _leading_target(targets, false)
	if unit.burst_target >= 0:
		var enemy := _enemies[unit.burst_target]
		var bonus := spec.technological_bonus_percent if enemy.definition.technological else 0
		hit.emit(unit.burst_target, roundi(spec.attack_damage * (100 + bonus) / 100.0))
	unit.burst_remaining -= 1
	var interval := spec.burst_step_seconds
	if unit.burst_remaining == 0:
		unit.burst_target = -1
		interval = spec.attack_seconds
	unit.next_attack_tick = tick + maxi(1, CombatClock.ticks_for(interval))

func _turret_targets(unit: DeploymentState.Placement, deployment: DeploymentState) -> Array[int]:
	var targets: Array[int] = []
	for id: int in _enemies:
		var enemy := _enemies[id]
		if enemy.is_targetable() and deployment.can_attack(unit, enemy.grid_cell(), enemy.definition.aerial):
			targets.append(id)
	return targets

func _leading_target(targets: Array[int], prefer_aerial: bool) -> int:
	var chosen := -1
	var furthest := -1.0
	var chosen_aerial := false
	for id in targets:
		var enemy := _enemies[id]
		var priority := prefer_aerial and enemy.definition.aerial
		if (priority and not chosen_aerial) or (priority == chosen_aerial and enemy.distance > furthest):
			chosen = id
			furthest = enemy.distance
			chosen_aerial = priority
	return chosen

func _in_reach(center: Vector2i, radius: int, unit: DeploymentState.Placement) -> bool:
	for cell in unit.spec.footprint(unit.anchor):
		var delta := (cell - center).abs()
		if maxi(delta.x, delta.y) <= radius:
			return true
	return false
