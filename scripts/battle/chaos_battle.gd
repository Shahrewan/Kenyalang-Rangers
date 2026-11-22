class_name ChaosBattle
extends BattleScene

signal completed

var run: ChaosRun

func _ready() -> void:
	%BackToMenu.hide()
	%Controls.hide()
	%MissionTitle.text = "Chaos · %s" % run.route_label
	%Legend.text = "Placeholder board art"
	%DeploymentController.preview_skills = false
	super._ready()

func _refresh() -> void:
	super._refresh()
	%DefeatedCount.text = "Defeated %d/%d" % [battle.configured_defeated, run.score.configured_enemies]
	if run.record_outcome(battle):
		completed.emit()
