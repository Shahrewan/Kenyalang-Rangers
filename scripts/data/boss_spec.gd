class_name BossSpec
extends BattleEnemyDefinition

@export var operation_id: StringName
@export_multiline var introduction: String
@export var ally_speed_scale := 1.0
@export var ally_speed_radius: int
@export var capturable := false
@export var phases: Array[BossPhase]

func phase_validation_error() -> String:
	if ally_speed_scale < 1.0 or not is_finite(ally_speed_scale) or ally_speed_radius < 0:
		return "Boss movement support needs a nonnegative radius and speed bonus."
	var previous := 100
	for phase in phases:
		if phase == null or phase.hp_percent >= previous:
			return "Boss phase thresholds must descend."
		var error := phase.validation_error()
		if not error.is_empty():
			return error
		if phase.reinforcement is BossSpec:
			return "Boss reinforcement orders need standard enemies."
		previous = phase.hp_percent
	return ""
