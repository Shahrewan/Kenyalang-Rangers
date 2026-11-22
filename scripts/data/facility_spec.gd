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
@export var mission_supply_stage: StringName

@export_group("Resource effects")
@export var work_seconds: float
@export var stock_capacity: int
@export var heal_per_kit: int
@export var cooldown_reduction_seconds: float

@export_group("Turret effects")
@export var splash_radius: int
@export var slow_speed_scale := 1.0
@export var slow_seconds: float
@export var burst_hits := 1
@export var burst_step_seconds: float
@export var technological_bonus_percent: int
@export var ground_damage_scale := 1.0

@export_group("Strategist effects")
@export var detection_radius: int
@export var mount_range_bonus: int
@export var heat_slow_percent: int
@export var discount_tokens: int

@export_group("Status zones")
@export var attack_rate_bonus_percent: int
@export var incoming_reduction_percent: int
@export var outgoing_reduction_percent: int
@export var ability_delay_seconds: float
