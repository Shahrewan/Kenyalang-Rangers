class_name FacilitySpec
extends DeploymentSpec

enum Category { RESOURCE, SENTRY, STRATEGIST, STATUS }
enum Role {
	LOGISTICS_POST, MEDIC_CABIN, SKILL_RELAY, DISPATCH_RELAY,
	SONIC_TURRET, ELECTRIC_TURRET, CANOPY_LAUNCHER,
	SENTRY_TOWER, FIREBREAK, SPECIALIST_CALLTOWER,
	COORDINATION_HUB, REINFORCED_COVER, DISRUPTION,
}

@export var category: Category
@export var role: Role
@export var recruitment_stage: StringName
@export var chaos_threshold: int

@export_group("Resource effects")
@export var work_seconds: float
@export var stock_capacity: int
@export var heal_per_kit: int
@export var cooldown_reduction_seconds: float
