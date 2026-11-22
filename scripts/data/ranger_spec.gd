class_name RangerSpec
extends DeploymentSpec

enum RangerClass { OFFENSE, DEFENSE, SUPPORT, SPECIALIST }
enum AttackPattern { SINGLE, SPLASH, FRONTAL }

@export var ranger_class: RangerClass
@export var recruitment_stage: StringName
@export var attack_pattern: AttackPattern
@export var splash_radius: int
@export var technological_bonus_percent: int
@export var prioritizes_focus := false
@export var records_enhancement: StringName
@export var focused_damage_bonus_percent: int
@export var active_skill: RangerSkill
