class_name StoryOperation
extends Resource

@export var title: String
@export var region: String
@export var stage: BattleStage
@export var roster: DeploymentRoster
@export var opening_rules: LogisticsRules
@export var ranger_ids: Array[StringName]
@export var supply_ids: Array[StringName]
@export var fixed_debuff: String
@export var buff_ids: Array[StringName]
@export var has_heat := false
@export var campaign_spec := false
@export var prerequisite: StringName
@export var min_control_level := 1
@export var optional_buff_limit := 1
@export var opening_tokens := 0
@export var fixed_debuff_ids: Array[StringName]
@export var clear_unlock_ids: Array[StringName]
@export var rewards: Dictionary
@export var dialogue: Array[Dictionary]
@export var hints: Array[Dictionary]
