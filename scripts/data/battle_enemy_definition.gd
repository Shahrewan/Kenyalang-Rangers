class_name BattleEnemyDefinition
extends Resource

@export var enemy_id: StringName
@export var display_name: String
@export var danger := 1
@export_multiline var counterplay: String
@export var tiles_per_second: float
@export var escape_penalty: int

@export var aerial := false
@export var technological := false

@export var max_hp := 100
@export var attack_damage := 6
@export var attack_seconds := 1.8
