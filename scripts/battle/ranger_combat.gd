class_name RangerCombat
extends RefCounted

signal hit(enemy_id: int, damage: int)

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

func basic_attack(unit: DeploymentState.Placement, deployment: DeploymentState, tick: int) -> void:
	if tick < unit.next_attack_tick or unit.spec.attack_damage <= 0:
		return
	var candidates := _candidates(unit, deployment)
	if candidates.is_empty():
		return
	var ranger := unit.ranger
	var primary := _leading(candidates, ranger != null and ranger.prioritizes_focus)
	var victims: Array[int] = [primary]
	if ranger != null:
		match ranger.attack_pattern:
			RangerSpec.AttackPattern.FRONTAL:
				victims = candidates
			RangerSpec.AttackPattern.SPLASH:
				var area := _square(_enemies[primary].grid_cell(), ranger.splash_radius)
				victims = _inside(candidates, area)
	unit.next_attack_tick = tick + CombatClock.ticks_for(unit.spec.attack_seconds)
	for id in victims:
		var enemy := _enemies[id]
		var bonus := 0
		if ranger != null:
			if enemy.definition.technological:
				bonus += ranger.technological_bonus_percent
			if unit.records_enhanced and enemy.focus_marked_until > tick:
				bonus += ranger.focused_damage_bonus_percent
		hit.emit(id, roundi(unit.spec.attack_damage * (100 + bonus) / 100.0))

func use_skill(unit: DeploymentState.Placement, target: Vector2i, deployment: DeploymentState) -> String:
	var skill := unit.ranger.active_skill
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
			hit.emit(id, skill.damage)
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
				hit.emit(id, skill.damage)
		RangerSkill.Effect.FRONTAL_STUN:
			unit.next_attack_tick = _clock.tick + CombatClock.ticks_for(unit.spec.attack_seconds)
			for id in candidates:
				var enemy := _enemies[id]
				enemy.stunned_until = maxi(enemy.stunned_until, until)
				hit.emit(id, skill.damage)
	return ""

func _candidates(unit: DeploymentState.Placement, deployment: DeploymentState) -> Array[int]:
	var result: Array[int] = []
	for id: int in _enemies:
		var enemy := _enemies[id]
		if enemy.is_targetable() and deployment.can_attack(unit, enemy.grid_cell(), enemy.definition.aerial):
			result.append(id)
	return result

func _leading(ids: Array[int], prefer_focus := false) -> int:
	var chosen := -1
	var chosen_distance := -1.0
	var chosen_marked := false
	for id in ids:
		var enemy := _enemies[id]
		var marked := prefer_focus and enemy.focus_marked_until > _clock.tick
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
