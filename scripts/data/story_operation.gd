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
@export var buff_choices: Array[PlanningBuff]
@export var has_heat := false
