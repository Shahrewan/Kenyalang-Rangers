class_name FacilityCombat
extends RefCounted

func advance(deployment: DeploymentState, tick: int) -> void:
	for unit: DeploymentState.Placement in deployment.placed.values():
		if tick < unit.next_utility_tick:
			continue
		if unit.facility != null and unit.facility.work_seconds > 0.0:
			_resource_pulse(unit, deployment, tick)
		elif unit.ranger != null and unit.ranger.repair_hp > 0:
			_repair(unit, deployment, tick)

func use_skill(unit: DeploymentState.Placement, target: Vector2i, deployment: DeploymentState) -> String:
	var target_id: StringName = deployment.occupancy.get(target, &"")
	if deployment.heal_ranger(target_id, unit.facility.heal_per_kit) == 0:
		return "Choose an injured Ranger for the kit."
	return ""

func _resource_pulse(unit: DeploymentState.Placement, deployment: DeploymentState, tick: int) -> void:
	var spec := unit.facility
	unit.next_utility_tick = tick + maxi(1, CombatClock.ticks_for(spec.work_seconds))
	var reduction := CombatClock.ticks_for(spec.cooldown_reduction_seconds)
	match spec.role:
		FacilitySpec.Role.MEDIC_CABIN:
			unit.stock = mini(spec.stock_capacity, unit.stock + 1)
		FacilitySpec.Role.SKILL_RELAY:
			for ally: DeploymentState.Placement in deployment.placed.values():
				if ally.skill_recharge_tick > tick and _in_reach(unit.anchor, spec.attack_range, ally):
					ally.skill_recharge_tick = maxi(tick, ally.skill_recharge_tick - reduction)
					ally.recharge_skill(tick)
		FacilitySpec.Role.DISPATCH_RELAY:
			deployment.reduce_deployment_cooldowns(reduction)

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

func _in_reach(center: Vector2i, radius: int, unit: DeploymentState.Placement) -> bool:
	for cell in unit.spec.footprint(unit.anchor):
		var delta := (cell - center).abs()
		if maxi(delta.x, delta.y) <= radius:
			return true
	return false
