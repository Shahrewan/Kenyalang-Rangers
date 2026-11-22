class_name BattleEnemy
extends RefCounted

var reinforcement := false

const MAX_DAMAGE_MARKS := 10

class DamageMark:
	var until: int
	var percent: int

var definition: BattleEnemyDefinition
var boss: BossSpec
var route: BattleRoute
var hp: int
var next_attack_tick := 0
var profile_ready_tick := 0
var aim_target: StringName
var aim_placement: DeploymentState.Placement
var fire_tick := 0
var blocked_by: StringName
var distance := 0.0
var focus_marked_until := 0
var immobilized_until := 0
var stunned_until := 0
var sonic_slow_until := 0
var sonic_speed_scale := 1.0
var tower_detected := false
var smoke_until := 0
var sprint_until := 0
var revealed_until := 0
var ability_ready_tick := 0
var ability_fire_tick := 0
var ability_target: StringName
var ability_placement: DeploymentState.Placement
var phase_index := 0
var phase_speed_scale := 1.0
var phase_heat_bonus := 0.0
var shield_hp := 0
var shield_until := 0
var _marks: Array[DamageMark] = []

func _init(enemy_definition: BattleEnemyDefinition, enemy_route: BattleRoute, tick := 0) -> void:
	definition = enemy_definition
	boss = definition as BossSpec
	hp = definition.max_hp
	route = enemy_route
	if definition.ability != null:
		ability_ready_tick = tick + CombatClock.ticks_for(definition.ability.first_seconds)

func advance(seconds: float, stop_at: float = INF) -> bool:
	var end := float(route.cells.size() - 1)
	distance = minf(minf(end, stop_at), distance + definition.tiles_per_second * seconds)
	if is_equal_approx(distance, end):
		distance = end
	return distance == end

func grid_position() -> Vector2:
	return route.position_at(distance)

func grid_cell() -> Vector2i:
	return Vector2i(grid_position().round())

func is_targetable(tick: int) -> bool:
	if not definition.concealed or tower_detected or tick < revealed_until:
		return true
	var ability := definition.ability
	return ability != null and ability.effect == EnemyAbility.Effect.SMOKE and tick >= smoke_until

func sprint_scale(tick: int) -> float:
	return definition.ability.speed_scale if tick < sprint_until else 1.0

func active_shield(tick: int) -> int:
	return shield_hp if tick < shield_until else 0

func take_damage(amount: int, tick: int) -> void:
	var absorbed := mini(amount, active_shield(tick))
	shield_hp -= absorbed
	hp = maxi(0, hp - (amount - absorbed))

func add_damage_mark(tick: int, until: int, percent: int) -> void:
	_marks = _marks.filter(func(mark: DamageMark) -> bool: return tick < mark.until)
	if _marks.size() == MAX_DAMAGE_MARKS:
		_marks.pop_front()
	var mark := DamageMark.new()
	mark.until = until
	mark.percent = percent
	_marks.append(mark)

func is_marked(tick: int) -> bool:
	return tick < focus_marked_until or _marks.any(func(mark: DamageMark) -> bool: return tick < mark.until)

func damage_mark_bonus(tick: int) -> int:
	var bonus := 0
	for mark in _marks:
		if tick < mark.until:
			bonus += mark.percent
	return bonus
