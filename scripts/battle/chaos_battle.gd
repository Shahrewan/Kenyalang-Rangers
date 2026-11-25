class_name ChaosBattle
extends BattleScene

signal completed

var run: ChaosRun
var _skin := FirstContactSkin.new()
var _portrait := StoryPortrait.new()

func _ready() -> void:
	%BackToMenu.hide()
	%Controls.hide()
	%MissionTitle.text = run.route_label
	%MissionTitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	%MissionTitle.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	%Legend.hide()
	_hud.illustrate(_skin)
	var assets := CampaignVisualAssets.new()
	if stage.heat_capacity > 0.0:
		var gauge := assets.load_art(assets.catalog.get("heat_meter", ""), "PackedScene") as PackedScene
		CampaignHeatDisplay.apply(%HeatRow, %HeatGauge, gauge)
	_illustrate_dialogue(_skin)
	_portrait.illustrated = true
	_portrait.assets = assets
	_portrait.custom_minimum_size.y = 196
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines: ScrollContainer = %DialogueText.get_parent()
	lines.get_parent().add_child(_portrait)
	lines.get_parent().move_child(_portrait, lines.get_index())
	%DeploymentController.illustrate(_skin)
	%DeploymentController.preview_skills = false
	super._ready()

func _open_boss_intro(id: int, boss: BossSpec) -> void:
	_present_boss(boss.enemy_id)
	super._open_boss_intro(id, boss)

func _open_boss_phase(id: int, phase: BossPhase) -> void:
	_present_boss(battle.active[id].definition.enemy_id)
	super._open_boss_phase(id, phase)

func _present_boss(id: StringName) -> void:
	_portrait.present("portrait." + String(id).trim_prefix("boss."), "confronting")
	%DialogueText.get_parent().scroll_vertical = 0

func _restart() -> void:
	super._restart()
	if battle != null:
		_board.illustrate_first_contact(_skin, stage.stage_id)

func _refresh() -> void:
	super._refresh()
	%DefeatedCount.text = "Defeated %d/%d" % [battle.configured_defeated, run.score.configured_enemies]
	if run.record_outcome(battle):
		completed.emit()
