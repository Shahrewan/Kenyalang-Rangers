class_name RangerSpec
extends DeploymentSpec

enum RangerClass { OFFENSE, DEFENSE, SUPPORT, SPECIALIST }
enum AttackPattern { SINGLE, SPLASH, FRONTAL, BOUNCE }
enum FieldKit { NONE, TRACKER, SABOTEUR, STRIKE }

@export var ranger_class: RangerClass
@export var recruitment_stage: StringName
@export var attack_pattern: AttackPattern
@export var splash_radius: int
@export var technological_bonus_percent: int
@export var prioritizes_focus := false
@export var records_enhancement: StringName
@export var focused_damage_bonus_percent: int
@export var active_skill: RangerSkill
@export var heal_hp: int
@export var ground_ranged := false
@export var technological_only := false
@export var bounce_radius: int

@export_group("Field kit")
@export var field_kit: FieldKit
@export var arrival_seconds: float
@export var pulse_seconds: float
@export var field_radius: int
@export var field_status_seconds: float
@export var field_damage: int
@export var retreat_refund_percent: int
@export var retreat_cooldown_reduction_seconds: float
@export var arrival_damage_step: int
@export var arrival_cost_step: int
@export var arrival_max_escalations: int

@export_group("Records tuning")
@export var records_bonus_hp: int
@export var records_counter_damage: int
@export var records_heal_interval_seconds: float
@export var records_redeploy_reduction_seconds: float

@export_group("Facility repair")
@export var repair_hp: int
@export var repair_seconds: float
@export var repair_range: int

func is_melee() -> bool:
	return uses_ground() and not ground_ranged

func has_expanded_field_kit() -> bool:
	return field_kit != FieldKit.NONE or (active_skill != null and active_skill.effect in [RangerSkill.Effect.HOWL, RangerSkill.Effect.SCAN])
