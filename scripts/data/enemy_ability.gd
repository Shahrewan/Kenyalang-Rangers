class_name EnemyAbility
extends Resource

enum Effect { SPRINT, SMOKE, JAM, TRACK, NET, KNOCKDOWN }

@export var effect: Effect
@export var first_seconds: float
@export var repeat_seconds: float
@export var windup_seconds: float
@export var duration_seconds: float
@export var radius: int
@export var speed_scale := 1.0
@export var ranger_attack_rate := 1.0
@export var skill_delay_seconds: float
@export var disruptible := false

func targets_self() -> bool:
	return effect == Effect.SPRINT or effect == Effect.SMOKE

func validation_error() -> String:
	for value in [first_seconds, repeat_seconds, windup_seconds, duration_seconds, skill_delay_seconds]:
		if not is_finite(value) or value < 0.0:
			return "Enemy ability timings must be nonnegative."
	if repeat_seconds <= 0.0 or duration_seconds <= 0.0 or radius < 0:
		return "An enemy ability needs a positive duration and repeat interval."
	if speed_scale <= 0.0 or not is_finite(speed_scale) or ranger_attack_rate <= 0.0 or not is_finite(ranger_attack_rate):
		return "Enemy ability multipliers must be positive."
	return ""
