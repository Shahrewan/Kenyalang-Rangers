class_name ModifierResolution
extends RefCounted

var stage: BattleStage
var entries: Array[DeploymentSpec] = []
var opening: LogisticsRules
var tokens := 0
var selection_error := ""
var opening_error := ""
var inactive_fixed: Dictionary[StringName, String] = {}
var score_entries: Dictionary[StringName, int] = {}
var ranger_slots := 0
var facility_slots := 0

func can_start() -> bool:
	return stage != null and opening != null and selection_error.is_empty() and opening_error.is_empty()

func modifier_points() -> int:
	var points := 0
	for value: int in score_entries.values():
		points += value
	return points
