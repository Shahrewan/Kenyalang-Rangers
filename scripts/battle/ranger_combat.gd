class_name RangerCombat
extends RefCounted

signal hit(enemy_id: int, damage: int, attacker: DeploymentState.Placement)
signal attack_presented(unit: DeploymentState.Placement, target_id: int, clip: StringName)
signal healing_presented(medic: DeploymentState.Placement, target: Vector2i)
signal kit_presented(unit: DeploymentState.Placement, cell: Vector2, cue: String)

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
	var scale := enemy.howl_speed_scale if tick < enemy.howl_slow_until else 1.0
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
			RangerSpec.AttackPattern.BOUNCE:
				var remaining: Array[int] = []
				for id: int in _enemies:
					var enemy := _enemies[id]
					if id != primary and enemy.is_targetable(tick) and (not enemy.definition.aerial or unit.spec.targets_aerial):
						remaining.append(id)
				for jump in 2:
					var origin_id := victims.back() as int
					var in_reach := _inside(remaining, _square(_enemies[origin_id].grid_cell(), ranger.bounce_radius))
					if in_reach.is_empty():
						break
					var next := _leading(in_reach)
					victims.append(next)
					remaining.erase(next)
			RangerSpec.AttackPattern.SPLASH:
				var area := _square(_enemies[primary].grid_cell(), ranger.splash_radius)
				victims = _inside(candidates, area)
	unit.next_attack_tick = tick + interval
	attack_presented.emit(unit, primary, &"Attack")
	for id in victims:
		if not _clock.is_running():
			return
		var enemy: BattleEnemy = _enemies.get(id)
		if enemy == null:
			continue
		var bonus := 0
		var counter_damage := 0
		if ranger != null:
			if enemy.definition.technological:
				bonus += ranger.technological_bonus_percent
			if unit.records_enhanced and enemy.is_marked(tick):
				bonus += ranger.focused_damage_bonus_percent
			if unit.records_enhanced and ranger.records_counter_damage > 0 and _attacks(enemy, unit, tick):
				counter_damage = ranger.records_counter_damage
		if ranger != null and ranger.attack_pattern == RangerSpec.AttackPattern.BOUNCE and id != primary:
			kit_presented.emit(unit, enemy.grid_position(), "boomerang_bounce")
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
	if skill.effect == RangerSkill.Effect.HOWL:
		return _howl(unit, skill)
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
	var candidates: Array[int] = []
	for id: int in _enemies:
		var enemy := _enemies[id]
		if deployment.can_attack(unit, enemy.grid_cell(), enemy.definition.aerial):
			candidates.append(id)
	if candidates.is_empty():
		return "No enemy in scan range."
	var target := _enemies[_highest_danger(candidates)]
	var until := _clock.tick + CombatClock.ticks_for(skill.status_seconds)
	target.revealed_until = maxi(target.revealed_until, until)
	target.add_damage_mark(_clock.tick, until, skill.mark_damage_percent)
	kit_presented.emit(unit, target.grid_position(), "marked")
	return ""

func _howl(unit: DeploymentState.Placement, skill: RangerSkill) -> String:
	var area := _square(unit.anchor, unit.spec.attack_range)
	var affected := false
	var until := _clock.tick + CombatClock.ticks_for(skill.status_seconds)
	for enemy: BattleEnemy in _enemies.values():
		if not area.has_point(enemy.grid_cell()):
			continue
		enemy.revealed_until = maxi(enemy.revealed_until, until)
		enemy.howl_slow_until = maxi(enemy.howl_slow_until, until)
		enemy.howl_speed_scale = skill.field_speed_scale
		affected = true
	if not affected:
		return "No enemy in howl range."
	kit_presented.emit(unit, Vector2(unit.anchor), "slow_field")
	return ""

func committed(unit: DeploymentState.Placement) -> void:
	match unit.ranger.field_kit:
		RangerSpec.FieldKit.TRACKER:
			var ids := _visible_ground()
			if ids.is_empty():
				return
			var center := _highest_danger(ids)
			var target := _enemies[center]
			var area := _square(target.grid_cell(), unit.ranger.field_radius)
			var until := _clock.tick + CombatClock.ticks_for(unit.ranger.field_status_seconds)
			for id in _inside(ids, area):
				_enemies[id].immobilized_until = maxi(_enemies[id].immobilized_until, until)
			unit.net_landed = true
			kit_presented.emit(unit, target.grid_position(), "tracker_net")
			hit.emit(center, unit.ranger.field_damage, unit)
		RangerSpec.FieldKit.SABOTEUR:
			_interference_pulse(unit, _clock.tick)

func withdrew(unit: DeploymentState.Placement, deployment: DeploymentState) -> void:
	var ranger := unit.ranger
	match ranger.field_kit:
		RangerSpec.FieldKit.TRACKER:
			if unit.net_landed:
				_refund(unit, deployment)
				deployment.reduce_deployment_cooldowns(CombatClock.ticks_for(ranger.retreat_cooldown_reduction_seconds))
				kit_presented.emit(unit, Vector2(unit.anchor), "wallet_credit")
		RangerSpec.FieldKit.SABOTEUR:
			_refund(unit, deployment)
			kit_presented.emit(unit, Vector2(unit.anchor), "emp")
			var area := _square(unit.anchor, ranger.field_radius)
			var until := _clock.tick + CombatClock.ticks_for(ranger.field_status_seconds)
			for id in _inside(_enemy_ids(), area):
				var enemy: BattleEnemy = _enemies.get(id)
				if not _clock.is_running():
					break
				if enemy == null:
					continue
				if enemy.definition.technological:
					enemy.stunned_until = maxi(enemy.stunned_until, until)
				hit.emit(id, ranger.field_damage, unit)

func _refund(unit: DeploymentState.Placement, deployment: DeploymentState) -> void:
	deployment.tokens += floori(unit.paid_cost * unit.ranger.retreat_refund_percent / 100.0)

func advance_kits(deployment: DeploymentState, tick: int) -> void:
	for unit: DeploymentState.Placement in deployment.placed.values():
		if not _clock.is_running():
			return
		if unit.ranger == null:
			continue
		match unit.ranger.field_kit:
			RangerSpec.FieldKit.STRIKE:
				if unit.arrival_tick > 0 and tick >= unit.arrival_tick:
					_arrive(unit)
			RangerSpec.FieldKit.SABOTEUR:
				if tick >= unit.next_utility_tick:
					_interference_pulse(unit, tick)

func _arrive(unit: DeploymentState.Placement) -> void:
	unit.arrival_tick = 0
	var ranger := unit.ranger
	var candidates := _visible_ground()
	var damage := ranger.field_damage + unit.arrival_rank * ranger.arrival_damage_step
	var cue := "strike_landed" if candidates.is_empty() else "strike_arrival"
	kit_presented.emit(unit, Vector2(unit.anchor), cue)
	unit.next_attack_tick = _clock.tick + CombatClock.ticks_for(ranger.attack_seconds)
	for strike in mini(unit.arrival_rank + 1, candidates.size()):
		if not _clock.is_running():
			break
		var target := _highest_danger(candidates)
		candidates.erase(target)
		kit_presented.emit(unit, _enemies[target].grid_position(), "strike_impact")
		hit.emit(target, damage, unit)

func _interference_pulse(unit: DeploymentState.Placement, tick: int) -> void:
	var interval := CombatClock.ticks_for(unit.ranger.pulse_seconds)
	unit.next_utility_tick = tick + interval
	unit.interference_radius = maxi(unit.ranger.field_radius, unit.interference_radius + 1)
	var area := _square(unit.anchor, unit.interference_radius)
	for enemy: BattleEnemy in _enemies.values():
		if enemy.definition.technological and area.has_point(enemy.grid_cell()):
			enemy.tech_interference_until = maxi(enemy.tech_interference_until, unit.next_utility_tick)
	kit_presented.emit(unit, Vector2(unit.anchor), "interference")

func _enemy_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_enemies.keys())
	return ids

func _visible_ground() -> Array[int]:
	var result: Array[int] = []
	for id: int in _enemies:
		var enemy := _enemies[id]
		if not enemy.definition.aerial and enemy.is_targetable(_clock.tick):
			result.append(id)
	return result

func _highest_danger(ids: Array[int]) -> int:
	var chosen := ids.front() as int
	for id in ids:
		var enemy := _enemies[id]
		var best := _enemies[chosen]
		if enemy.definition.danger > best.definition.danger or (enemy.definition.danger == best.definition.danger and enemy.distance > best.distance):
			chosen = id
	return chosen

func _candidates(unit: DeploymentState.Placement, deployment: DeploymentState) -> Array[int]:
	var result: Array[int] = []
	for id: int in _enemies:
		var enemy := _enemies[id]
		if unit.ranger != null and unit.ranger.technological_only and not enemy.definition.technological:
			continue
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
