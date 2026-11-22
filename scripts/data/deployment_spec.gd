class_name DeploymentSpec
extends Resource

enum Kind { GROUND, GROUND_PAIR, ELEVATED, FACILITY_PAIR, SENTRY }
enum Skill { NONE, IMMEDIATE, TARGETED }

@export var id: StringName
@export var label: String
@export var kind: Kind
@export var cost: int
@export var max_hp := 100
@export var attack_damage := 0
@export var attack_seconds := 1.0
@export var block_capacity := 0
@export var attack_range: int
@export var targets_aerial := false
@export var skill: Skill
@export var logistics_post := false
@export_range(1, 100) var level := 1
@export var growth: DeployableGrowth
@export var build_seconds := 0.0
@export var build_cooldown_seconds := 0.0
@export var redeploy_seconds := 5.0

func footprint(anchor: Vector2i) -> Array[Vector2i]:
	if kind == Kind.GROUND_PAIR or kind == Kind.FACILITY_PAIR:
		return [anchor, anchor + Vector2i.RIGHT]
	return [anchor]

func reserved(anchor: Vector2i) -> Array[Vector2i]:
	return [anchor + Vector2i.UP] if kind == Kind.SENTRY else []

func is_ranger() -> bool:
	return kind != Kind.FACILITY_PAIR and kind != Kind.SENTRY

func is_melee() -> bool:
	return kind == Kind.GROUND or kind == Kind.GROUND_PAIR
