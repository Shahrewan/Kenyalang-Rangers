class_name ChaosBattle
extends BattleScene

signal completed

var run: ChaosRun
var _skin := FirstContactSkin.new()

func _ready() -> void:
	%BackToMenu.hide()
	%Controls.hide()
	%MissionTitle.text = "Chaos · %s" % run.route_label
	%Legend.hide()
	_hud.illustrate(_skin)
	%DeploymentController.illustrate(_skin, stage.stage_id)
	%DeploymentController.preview_skills = false
	super._ready()

func _restart() -> void:
	super._restart()
	if battle != null:
		_board.illustrate_first_contact(_skin, stage.stage_id)

func _refresh() -> void:
	super._refresh()
	%DefeatedCount.text = "Defeated %d/%d" % [battle.configured_defeated, run.score.configured_enemies]
	if run.record_outcome(battle):
		completed.emit()
