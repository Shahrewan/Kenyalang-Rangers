class_name BossPhase
extends Resource

@export_range(1, 99) var hp_percent := 50
@export_multiline var announcement: String
@export var speed_scale := 1.0
@export var extra_heat_per_second: float
@export var temporary_hp: int
@export var protection_seconds: float
@export var reinforcement: BattleEnemyDefinition
@export var reinforcement_count: int
@export var reinforcement_delay_seconds: float
@export var reinforcement_interval_seconds: float

func validation_error() -> String:
	if hp_percent <= 0 or hp_percent >= 100 or speed_scale <= 0.0 or not is_finite(speed_scale):
		return "Boss phases need an interior HP threshold and positive speed scale."
	for value in [extra_heat_per_second, protection_seconds, reinforcement_delay_seconds, reinforcement_interval_seconds]:
		if not is_finite(value) or value < 0.0:
			return "Boss phase outputs and timings must be nonnegative."
	if temporary_hp < 0 or (temporary_hp > 0 and protection_seconds <= 0.0):
		return "Boss temporary HP needs a positive duration."
	if reinforcement_count < 0 or (reinforcement_count > 0 and reinforcement == null):
		return "Boss reinforcements need a valid enemy and count."
	return ""
