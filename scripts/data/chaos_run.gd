class_name ChaosRun
extends RefCounted

var route_label: String
var score: ChaosScore
var integrity := 100
var configured_defeated := 0
var escaped := 0
var lost := false
var finished := false

func _init(arena: String, plan: ModifierResolution) -> void:
	route_label = arena
	score = ChaosScore.new(plan)

func record_outcome(battle: BattleSimulation) -> bool:
	if finished or battle.outcome == BattleSimulation.Outcome.RUNNING:
		return false
	integrity = battle.integrity
	configured_defeated = battle.configured_defeated
	escaped = battle.escaped
	lost = battle.outcome == BattleSimulation.Outcome.LOST
	finished = true
	return true

func qualifies() -> bool:
	return finished and not lost and integrity > 0 and escaped == 0 and configured_defeated == score.configured_enemies
