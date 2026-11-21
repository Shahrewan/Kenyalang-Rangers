class_name BattleStage
extends Resource

@export var stage_id: StringName
@export var map: BattleMap
@export var routes: Array[BattleRoute]
@export var waves: Array[BattleWave]

func validation_error() -> String:
	if map == null:
		return "A stage needs a map."
	var error := map.validation_error(routes)
	if not error.is_empty():
		return error
	for wave in waves:
		if wave == null or not is_finite(wave.rest_after_seconds) or wave.rest_after_seconds < 0.0:
			return "A wave needs a nonnegative rest."
		for group in wave.groups:
			if group == null or group.count < 0:
				return "A spawn group needs a nonnegative count."
			if group.count == 0:
				continue
			if group.route_index < 0 or group.route_index >= routes.size():
				return "A spawn group needs a valid route."
			if not is_finite(group.interval_seconds) or group.interval_seconds < 0.0:
				return "A spawn group needs a nonnegative interval."
			if group.enemy == null or not is_finite(group.enemy.tiles_per_second) or group.enemy.tiles_per_second <= 0.0 or group.enemy.escape_penalty < 0:
				return "A spawn group needs an enemy with positive speed and a nonnegative escape cost."
	return ""
