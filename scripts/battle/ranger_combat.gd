class_name RangerCombat
extends RefCounted

signal hit(enemy_id: int, damage: int, attacker: DeploymentState.Placement)
signal attack_presented(unit: DeploymentState.Placement, target_id: int, clip: StringName)
signal healing_presented(medic: DeploymentState.Placement, target: Vector2i)

class SlowField:
	var area: Rect2i
	var deadline: int
	var speed_scale: float
	var affects_aerial: bool

var fields: Array[SlowField] = []
var _clock: CombatClock
var _enemies: Dictionary[int, BattleEnemy]

func _init(clock: CombatClock, enemies: Dictionary[int, BattleEnemy]) -> void:
	_clock = clock
	_enemies = enemies

func expire_fields(tick: int) -> void:
	for index in range(fields.size() - 1, -1, -1):
		if tick >= fields[index].deadline:
			fields.remove_at(index)

func movement_scale(enemy: BattleEnemy, tick: int) -> float:
	if tick < maxi(enemy.immobilized_until, enemy.stunned_until):
		return 0.0
	var scale := 1.0
	if not fields.is_empty():
		var cell := enemy.grid_cell()
		for field in fields:
			if (field.affects_aerial or not enemy.definition.aerial) and field.area.has_point(cell):
				scale = minf(scale, field.speed_scale)
	return scale

func basic_attack(unit: DeploymentState.Placement, deployment: DeploymentState, tick: int, interval: int) -> void:
	unit.update_basic_interval(interval, tick)
	if not unit.can_act(tick) or tick < unit.next_attack_tick:
		return
	var ranger := unit.ranger
	if ranger != null and ranger.heal_hp > 0:
		if _heal_ally(unit, deployment):
			unit.next_attack_tick = tick + interval
		return
	var candidates := _candidates(unit, deployment)
	if candidates.is_empty():
		return
	var primary := _leading(candidates, ranger != null and ranger.prioritizes_focus)
	var victims: Array[int] = [primary]
	if ranger != null:
		match ranger.attack_pattern:
			RangerSpec.AttackPattern.FRONTAL:
				victims = candidates
			RangerSpec.AttackPattern.SPLASH:
				var area := _square(_enemies[primary].grid_cell(), ranger.splash_radius)
				victims = _inside(candidates, area)
	unit.next_attack_tick = tick + interval
	attack_presented.emit(unit, primary, &"Attack")
	for id in victims:
		if not _clock.is_running():
			return
		var enemy := _enemies[id]
		var bonus := 0
		var counter_damage := 0
		if ranger != null:
			if enemy.definition.technological:
				bonus += ranger.technological_bonus_percent
			if unit.records_enhanced and enemy.is_marked(tick):
				bonus += ranger.focused_damage_bonus_percent
			if unit.records_enhanced and ranger.records_counter_damage > 0 and _attacks(enemy, unit, tick):
				counter_damage = ranger.records_counter_damage
		hit.emit(id, roundi(unit.spec.attack_damage * (100 + bonus) / 100.0) + counter_damage, unit)

func _attacks(enemy: BattleEnemy, unit: DeploymentState.Placement, tick: int) -> bool:
	if tick < enemy.stunned_until:
		return false
	return enemy.aim_placement == unit or (enemy.definition.attack_profile == null and enemy.blocked_by == unit.id)

func _heal_ally(medic: DeploymentState.Placement, deployment: DeploymentState) -> bool:
	var reach := deployment.coverage(medic.spec, medic.anchor, medic.facing)
	var chosen: DeploymentState.Placement
	for ally: DeploymentState.Placement in deployment.placed.values():
		if not ally.spec.is_ranger() or ally.hp >= ally.spec.max_hp:
			continue
		for tile in ally.spec.footprint(ally.anchor):
			if tile in reach and (chosen == null or ally.hp < chosen.hp):
				chosen = ally
				break
	if chosen == null or deployment.heal_ranger(chosen.id, medic.ranger.heal_hp) == 0:
		return false
	healing_presented.emit(medic, chosen.anchor)
	return true

func use_skill(unit: DeploymentState.Placement, target: Vector2i, deployment: DeploymentState, interval: int) -> String:
	var skill := unit.ranger.active_skill
	if skill.effect == RangerSkill.Effect.TREATMENT:
		return _treat(target, deployment, skill.healing)
	if skill.effect == RangerSkill.Effect.SCAN:
		return _scan(unit, deployment, skill)
	var candidates := _candidates(unit, deployment)
	if candidates.is_empty():
		return "No eligible enemy in range."
	var until := _clock.tick + CombatClock.ticks_for(skill.status_seconds)
	match skill.effect:
		RangerSkill.Effect.FOCUS:
			var aimed := _inside(candidates, Rect2i(target, Vector2i.ONE))
			if aimed.is_empty():
				return "No eligible enemy on that tile."
			var id := _leading(aimed)
			var enemy := _enemies[id]
			enemy.focus_marked_until = _clock.tick + CombatClock.ticks_for(skill.focus_seconds)
			enemy.immobilized_until = maxi(enemy.immobilized_until, until)
			attack_presented.emit(unit, id, &"Skill")
			hit.emit(id, skill.damage, unit)
		RangerSkill.Effect.EMP_FIELD:
			var primary := _leading(candidates)
			var area := _square(_enemies[primary].grid_cell(), skill.splash_radius)
			var field := SlowField.new()
			field.area = area
			field.deadline = until
			field.speed_scale = skill.field_speed_scale
			field.affects_aerial = unit.spec.targets_aerial
			fields.append(field)
			for id in _inside(candidates, area):
				hit.emit(id, skill.damage, unit)
		RangerSkill.Effect.FRONTAL_STUN:
			unit.update_basic_interval(interval, _clock.tick)
			unit.next_attack_tick = _clock.tick + interval
			for id in candidates:
				var enemy := _enemies[id]
				enemy.stunned_until = maxi(enemy.stunned_until, until)
				hit.emit(id, skill.damage, unit)
	return ""

func _treat(cell: Vector2i, deployment: DeploymentState, healing: int) -> String:
	var target_id := deployment.interaction_id(cell)
	var ally: DeploymentState.Placement = deployment.placed.get(target_id)
	if ally == null or not ally.spec.is_ranger():
		return "Choose an injured or affected Ranger."
	var affected := _clock.tick < maxi(maxi(ally.jammed_until, ally.attack_slow_until), maxi(ally.entangled_until, ally.knocked_down_until))
	if deployment.heal_ranger(target_id, healing) == 0 and not affected:
		return "Choose an injured or affected Ranger."
	ally.jammed_until = 0
	ally.attack_slow_until = 0
	ally.entangled_until = 0
	ally.knocked_down_until = 0
	return ""

func _scan(unit: DeploymentState.Placement, deployment: DeploymentState, skill: RangerSkill) -> String:
	var target: BattleEnemy
	for enemy: BattleEnemy in _enemies.values():
		if not deployment.can_attack(unit, enemy.grid_cell(), enemy.definition.aerial):
			continue
		if target == null or enemy.definition.danger > target.definition.danger:
			target = enemy
		elif enemy.definition.danger == target.definition.danger and enemy.distance > target.distance:
			target = enemy
	if target == null:
		return "No enemy in scan range."
	var until := _clock.tick + CombatClock.ticks_for(skill.status_seconds)
	target.revealed_until = maxi(target.revealed_until, until)
	target.add_damage_mark(_clock.tick, until, skill.mark_damage_percent)
	return ""

func _candidates(unit: DeploymentState.Placement, deployment: DeploymentState) -> Array[int]:
	var result: Array[int] = []
	for id: int in _enemies:
		var enemy := _enemies[id]
		if enemy.is_targetable(_clock.tick) and deployment.can_attack(unit, enemy.grid_cell(), enemy.definition.aerial):
			result.append(id)
	return result

func _leading(ids: Array[int], prefer_focus := false) -> int:
	var chosen := -1
	var chosen_distance := -1.0
	var chosen_marked := false
	for id in ids:
		var enemy := _enemies[id]
		var marked := prefer_focus and enemy.is_marked(_clock.tick)
		if (marked and not chosen_marked) or (marked == chosen_marked and enemy.distance > chosen_distance):
			chosen = id
			chosen_distance = enemy.distance
			chosen_marked = marked
	return chosen

func _inside(ids: Array[int], area: Rect2i) -> Array[int]:
	return ids.filter(func(id: int) -> bool: return area.has_point(_enemies[id].grid_cell()))

func _square(center: Vector2i, radius: int) -> Rect2i:
	var offset := Vector2i.ONE * radius
	return Rect2i(center - offset, offset * 2 + Vector2i.ONE)
