class_name DeployableGrowth
extends Resource

# Each positive value is an authored Lv.100 endpoint.
@export var hp: int
@export var attack_damage: int
@export var healing: int
@export var repair: int
@export var skill_damage: int

@export_group("Facility effects")
@export var cooldown_reduction_seconds: float
@export var detection_radius: int
@export var heat_slow_percent: int
@export var discount_tokens: int
@export var attack_rate_bonus_percent: int
@export var incoming_reduction_percent: int
@export var outgoing_reduction_percent: int
