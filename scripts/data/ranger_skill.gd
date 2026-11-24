class_name RangerSkill
extends Resource

enum Effect { FOCUS, EMP_FIELD, FRONTAL_STUN, SCAN, TREATMENT, HOWL }

@export var label: String
@export var effect: Effect
@export var requires_records := false
@export_range(1, 10) var max_charges := 1
@export var recharge_seconds: float
@export var damage: int
@export var healing: int
@export var status_seconds: float
@export var focus_seconds: float
@export var splash_radius: int
@export var mark_damage_percent: int
@export_range(0.0, 1.0) var field_speed_scale := 1.0
