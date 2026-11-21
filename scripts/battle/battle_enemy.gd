class_name BattleEnemy
extends RefCounted

var definition: BattleEnemyDefinition
var route: BattleRoute
var distance := 0.0

func _init(enemy_definition: BattleEnemyDefinition, enemy_route: BattleRoute) -> void:
	definition = enemy_definition
	route = enemy_route

func advance(seconds: float) -> bool:
	var end := float(route.cells.size() - 1)
	distance = minf(end, distance + definition.tiles_per_second * seconds)
	if is_equal_approx(distance, end):
		distance = end
	return distance == end

func grid_position() -> Vector2:
	return route.position_at(distance)
