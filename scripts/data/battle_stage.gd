class_name BattleStage
extends Resource

@export var stage_id: StringName
@export var map: BattleMap
@export var routes: Array[BattleRoute]
@export var opening_delay_seconds := 0.0
@export var first_clear_funds := 0
@export var first_perfect_funds := 0
@export var heat_capacity: float
@export var heat_integrity_loss: int
@export var heat_gain_scale := 1.0
@export var capture_boss_id: StringName
@export var waves: Array[BattleWave]

func enemy_count() -> int:
	var count := 0
	for wave in waves:
		for group in wave.groups:
			count += group.count
	return count

func validation_error() -> String:
	if not is_finite(opening_delay_seconds) or opening_delay_seconds < 0.0 or first_clear_funds < 0 or first_perfect_funds < 0:
		return "Opening delay and rewards must be nonnegative."
	if not is_finite(heat_capacity) or heat_capacity < 0.0 or not is_finite(heat_gain_scale) or heat_gain_scale <= 0.0 or (heat_capacity > 0.0 and heat_integrity_loss <= 0):
		return "A Heat stage needs a positive cap and Integrity loss."
	if map == null:
		return "A stage needs a map."
	var error := map.validation_error(routes)
	if not error.is_empty():
		return error
	var capturable_count := 0
	var final_capture_wave := false
	for wave in waves:
		if wave == null or not is_finite(wave.rest_after_seconds) or wave.rest_after_seconds < 0.0:
			return "A wave needs a nonnegative rest."
		var wave_count := 0
		var capture_in_wave := false
		for group in wave.groups:
			if group == null or group.count < 0:
				return "A spawn group needs a nonnegative count."
			if group.count == 0:
				continue
			wave_count += group.count
			if group.route_index < 0 or group.route_index >= routes.size():
				return "A spawn group needs a valid route."
			if not is_finite(group.interval_seconds) or group.interval_seconds < 0.0:
				return "A spawn group needs a nonnegative interval."
			if group.enemy == null or not is_finite(group.enemy.tiles_per_second) or group.enemy.tiles_per_second <= 0.0 or group.enemy.escape_penalty < 0:
				return "A spawn group needs an enemy with positive speed and a nonnegative escape cost."
			if not is_finite(group.enemy.heat_per_second) or group.enemy.heat_per_second < 0.0:
				return "Enemy Heat output must be nonnegative."
			var profile := group.enemy.attack_profile
			if profile != null and (profile.radius < 0 or not is_finite(profile.windup_seconds) or profile.windup_seconds < 0.0):
				return "Enemy range and windup must be nonnegative."
			var ability := group.enemy.ability
			if ability != null and not ability.validation_error().is_empty():
				return ability.validation_error()
			var boss := group.enemy as BossSpec
			if boss != null:
				var phase_error := boss.phase_validation_error()
				if not phase_error.is_empty():
					return phase_error
				if boss.capturable and boss.enemy_id == capture_boss_id:
					capture_in_wave = true
					capturable_count += group.count
		if wave_count > 0:
			final_capture_wave = capture_in_wave and wave_count == 1
	if not capture_boss_id.is_empty() and (capturable_count != 1 or not final_capture_wave):
		return "The capture objective needs its boss alone in the final populated wave."
	return ""
