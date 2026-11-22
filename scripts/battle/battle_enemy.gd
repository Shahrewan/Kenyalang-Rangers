class_name BattleEnemy
extends RefCounted

var definition: BattleEnemyDefinition
var route: BattleRoute
var hp: int
var next_attack_tick := 0
var profile_ready_tick := 0
var aim_target: StringName
var fire_tick := 0
var blocked_by: StringName
var distance := 0.0
var focus_marked_until := 0
var immobilized_until := 0
var stunned_until := 0

func _init(enemy_definition: BattleEnemyDefinition, enemy_route: BattleRoute) -> void:
	definition = enemy_definition
	hp = definition.max_hp
	route = enemy_route

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
