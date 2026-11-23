class_name BattleScene
extends Control

signal sound_requested(id: String)
signal abandon_requested
signal operation_finished(report: Dictionary)
signal sandbox_exit_requested
signal settings_requested
signal controls_requested

@export var stage: BattleStage
@export var sandbox := false
@export var sandbox_title := "Offense sandbox"
@export var sandbox_legend := "Placeholder art · T: Technological · A: Aerial · Teal tiles: EMP slow"
var sandbox_return_label := "Exit sandbox"
var sandbox_practice_hits := false
var campaign := false
var operation_plan: OperationPlan
var save_path := FirstContactProgress.DEFAULT_PATH
var _progress: FirstContactProgress
var _reported := false
var _tips := true
var _boss_briefing := false
var _alert_deadlines: Dictionary[String, int] = {}

@onready var _hud = %Header
@onready var _pause_overlay: BattlePauseOverlay = %PauseOverlay
@onready var _board: BattleBoard = %Board
@onready var _tip: Label = %MissionTip
@onready var _status: Label = %Status
@onready var _back: Button = %BackToMenu
@onready var _pause: Button = %Pause
@onready var _speed: Button = %Speed
@onready var _dialogue_button: Button = %OpenDialogue
@onready var _defeat: Button = %DefeatEnemy
@onready var _retry: Button = %Retry
@onready var _opening: OptionButton = %Opening
@onready var _dialogue: ColorRect = %Dialogue

var battle: BattleSimulation

func _ready() -> void:
	%DeploymentController.sound_requested.connect(func(id: String) -> void: sound_requested.emit(id))
	_pause.pressed.connect(_toggle_pause)
	_pause_overlay.resume_requested.connect(_resume)
	_pause_overlay.abandon_requested.connect(_abandon)
	_pause_overlay.settings_requested.connect(func() -> void: settings_requested.emit())
	_pause_overlay.controls_requested.connect(func() -> void: controls_requested.emit())
	_speed.pressed.connect(_toggle_speed)
	_dialogue_button.pressed.connect(_open_preview_dialogue)
	_defeat.pressed.connect(_defeat_first)
	_retry.pressed.connect(_restart)
	%Continue.pressed.connect(close_dialogue)
	%Skip.pressed.connect(_skip_dialogue)
	if campaign:
		_prepare_campaign()
		if operation_plan != null:
			_back.hide()
			%Controls.hide()
		_opening.hide()
		_dialogue_button.hide()
		_defeat.hide()
		%DeploymentController.preview_skills = false
	if sandbox:
		%MissionTitle.text = sandbox_title
		%Legend.text = sandbox_legend
		_back.text = sandbox_return_label
		_back.pressed.connect(_leave_sandbox)
		_opening.hide()
		_defeat.visible = sandbox_practice_hits
		if sandbox_practice_hits:
			_defeat.text = "Practice hit"
		%DeploymentController.preview_skills = false
		StoryUI.size_buttons(self)
	_opening.add_item("First Contact")
	_opening.add_item("Normal loadout")
	_opening.add_item("D05 Fixed Stockpile")
	_opening.item_selected.connect(_change_opening)
	_restart()

func _prepare_campaign() -> void:
	_progress = FirstContactProgress.new(save_path)
	%Legend.hide()
	%MissionTitle.text = "First Contact"
	%DialogueTitle.text = "First Contact"
	%DialogueText.text = (
		"Operations Manager: Our patrol spotted movement at the old chokepoint.\n\n"
		+ "Deploy the free Starter Post across two raised tiles. D01 yields 9 Tokens per 10 combat seconds.\n"
		+ "Place Scout Sniper on a raised tile near the bend. Place Patrolman on the path facing the entry.\n"
		+ "Rangers attack automatically. Keep Integrity above zero through both waves."
	)

func _change_opening(index: int) -> void:
	%DeploymentController.mode = index
	_restart()

func _physics_process(_delta: float) -> void:
	if battle == null:
		return
	battle.clock.advance_frame()
	_refresh()

func open_dialogue() -> void:
	if battle == null or battle.clock.stopped:
		return
	battle.clock.dialogue_open = true
	_refresh()
	%Continue.grab_focus()

func _open_preview_dialogue() -> void:
	%DialogueTitle.text = "Dialogue preview"
	%DialogueText.text = "The messenger withdraws off the battlefield."
	open_dialogue()

func _open_boss_intro(_id: int, boss: BossSpec) -> void:
	_open_boss_briefing(boss.display_name, boss.introduction)

func _open_boss_phase(id: int, phase: BossPhase) -> void:
	var enemy := battle.active[id]
	_open_boss_briefing("%s · Phase %d" % [enemy.definition.display_name, enemy.phase_index + 1], phase.announcement)

func _open_boss_briefing(title: String, message: String) -> void:
	if message.is_empty():
		return
	_boss_briefing = true
	%DialogueTitle.text = title
	%DialogueText.text = message
	open_dialogue()

func close_dialogue() -> void:
	if battle == null or not battle.clock.dialogue_open:
		return
	if not campaign and not _boss_briefing:
		battle.record_cinematic_withdrawal()
	_boss_briefing = false
	battle.clock.dialogue_open = false
	_refresh()
	if _uses_combat_presentation():
		_pause.grab_focus()
	else:
		_dialogue_button.grab_focus()

func _skip_dialogue() -> void:
	_tips = false
	close_dialogue()

func _restart() -> void:
	var error := "No stage configured." if stage == null else stage.validation_error()
	if not error.is_empty():
		_status.show()
		_status.text = error
		_pause.disabled = true
		_speed.disabled = true
		_dialogue_button.disabled = true
		_defeat.disabled = true
		_retry.disabled = true
		return
	battle = BattleSimulation.new(stage)
	battle.boss_intro.connect(func(_serial: int, _boss: BossSpec) -> void: sound_requested.emit("boss"))
	battle.boss_phase_changed.connect(func(_serial: int, _phase: BossPhase) -> void: sound_requested.emit("boss"))
	_alert_deadlines.clear()
	battle.heat_overflow.connect(_critical_notice.bind("heat", "Heat overflow · Integrity lost"))
	battle.siege_hit.connect(_critical_notice.bind("siege", "Siege hit · Facility struck"))
	battle.boss_intro.connect(_open_boss_intro)
	battle.boss_phase_changed.connect(_open_boss_phase)
	_boss_briefing = false
	_pause_overlay.hide()
	_status.hide()
	%HeatRow.visible = stage.heat_capacity > 0.0
	if %HeatRow.visible:
		%HeatGauge.max_value = stage.heat_capacity
	_board.battle_map = stage.map
	_board.routes = stage.routes
	_board.battle = battle
	%DeploymentController.setup(battle, stage.map, operation_plan)
	_reported = false
	_tips = true
	_tip.text = ""
	if _uses_combat_presentation():
		battle.deployment = %DeploymentController.state
		_board.show_combat_hp = true
	if campaign:
		_open_operation()
	_refresh()

func _critical_notice(cue: String, message: String) -> void:
	_alert_deadlines[message] = battle.clock.tick + CombatClock.TICKS_PER_SECOND * 2
	sound_requested.emit(cue)

func _open_operation() -> void:
	open_dialogue()

func _toggle_pause() -> void:
	if battle == null or battle.clock.stopped or battle.clock.dialogue_open:
		return
	if battle.clock.paused:
		_resume()
	else:
		battle.clock.paused = true
		if _uses_combat_presentation():
			_pause_overlay.show_battle(stage, battle, operation_plan != null, settings_requested.has_connections())
		_refresh()

func request_back() -> void:
	if battle == null:
		return
	if battle.clock.dialogue_open:
		_skip_dialogue()
	elif _pause_overlay.visible:
		_pause_overlay.request_back()
	else:
		_toggle_pause()

func _resume() -> void:
	battle.clock.paused = false
	_pause_overlay.hide()
	_refresh()
	_pause.grab_focus()

func _abandon() -> void:
	if battle.clock.paused and operation_plan != null:
		battle.clock.stopped = true
		abandon_requested.emit()

func _toggle_speed() -> void:
	battle.clock.set_speed(3 - battle.clock.get_speed())
	_refresh()

func _defeat_first() -> void:
	if sandbox_practice_hits:
		_practice_hit()
	elif not battle.active.is_empty():
		battle.defeat_enemy(battle.active.keys()[0])
	_refresh()

func _leave_sandbox() -> void:
	if sandbox_exit_requested.has_connections():
		sandbox_exit_requested.emit()
	else:
		get_tree().quit()

func _active_boss_id() -> int:
	for id: int in battle.active:
		if battle.active[id].boss != null:
			return id
	return 0

func _practice_hit() -> void:
	var id := _active_boss_id()
	if id == 0:
		return
	var enemy := battle.active[id]
	var goal := 0
	if enemy.phase_index < enemy.boss.phases.size():
		var phase := enemy.boss.phases[enemy.phase_index]
		goal = floori(enemy.boss.max_hp * phase.hp_percent / 100.0)
	if enemy.hp > goal:
		battle.damage_enemy(id, enemy.hp - goal + enemy.active_shield(battle.clock.tick))

func _refresh() -> void:
	var placement: DeploymentState = %DeploymentController.state
	_hud.render(battle, battle.expected_enemy_count, placement.tokens)
	if %HeatRow.visible:
		%HeatGauge.value = battle.heat
		%HeatLabel.text = "Heat %d/%d" % [floori(battle.heat), roundi(stage.heat_capacity)]
	var warned := battle.recon_entries()
	if not warned.is_empty() and not %ReconNotice.visible:
		sound_requested.emit("recon")
	%ReconNotice.visible = not warned.is_empty()
	if %ReconNotice.visible:
		var names := PackedStringArray()
		for entry in warned:
			var index := stage.map.spawns.find(entry)
			names.append("Entry" if stage.map.spawns.size() == 1 else "Entry %s" % char(65 + index))
		%ReconNotice.text = "Wave %d in %d s · %s" % [battle.wave_number, battle.recon_seconds_left(), ", ".join(names)]
	if campaign:
		_update_campaign_tip()
	if battle.outcome != BattleSimulation.Outcome.RUNNING:
		_status.show()
		_status.text = _outcome_label()
	else:
		var alerts := PackedStringArray()
		for message: String in _alert_deadlines.keys():
			if _alert_deadlines[message] > battle.clock.tick:
				alerts.append(message)
			else:
				_alert_deadlines.erase(message)
		_status.text = "   |   ".join(alerts)
		_status.visible = not alerts.is_empty()
	var clock := battle.clock
	_pause.text = "Resume" if clock.paused else "Pause"
	_speed.text = "%d×" % clock.get_speed()
	_back.disabled = clock.dialogue_open
	_pause.disabled = clock.stopped or clock.dialogue_open
	_speed.disabled = clock.stopped or clock.dialogue_open or (_uses_combat_presentation() and clock.paused)
	_dialogue_button.disabled = clock.stopped or clock.dialogue_open
	_defeat.disabled = not clock.is_running() or battle.active.is_empty()
	if sandbox_practice_hits and _active_boss_id() == 0:
		_defeat.disabled = true
	_retry.disabled = clock.dialogue_open
	_opening.disabled = clock.dialogue_open
	_dialogue.visible = clock.dialogue_open
	_pause_overlay.visible = _uses_combat_presentation() and clock.paused and not clock.dialogue_open and not clock.stopped
	$Content.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED if _dialogue.visible or _pause_overlay.visible else Control.FOCUS_BEHAVIOR_INHERITED
	_board.queue_redraw()

func _uses_combat_presentation() -> bool:
	return campaign or sandbox or operation_plan != null

func _outcome_label() -> String:
	if battle.outcome == BattleSimulation.Outcome.LOST:
		return "Defeat"
	if not battle.captured_boss_id.is_empty():
		return "Boss captured"
	return "Perfect clear" if battle.is_perfect() else "Clear"

func _update_campaign_tip() -> void:
	if battle.outcome != BattleSimulation.Outcome.RUNNING:
		if not _reported:
			_reported = true
			_publish_result()
		return
	if not _tips:
		_tip.text = ""
	elif battle.deployment.posts_deployed == 0:
		_tip.text = "Drag the free Starter Post onto two raised tiles."
	elif battle.deployment.placed.size() < 3:
		_tip.text = "Cover the bend with Scout. Block the lower path with a left-facing Patrolman."
	else:
		_tip.text = "Hold a Ranger to retreat. Pause to review the field."

func _publish_result() -> void:
	var profile := _progress.snapshot()
	var first := 0
	var perfect := 0
	var failed := false
	if battle.outcome == BattleSimulation.Outcome.LOST:
		_tip.text = "Integrity reached zero. Restart to retry First Contact with the same supply."
	else:
		var reward := _progress.record_clear(battle.is_perfect(), stage.first_clear_funds, stage.first_perfect_funds)
		failed = reward < 0
		if not failed:
			first = stage.first_clear_funds if not profile.first_clear else 0
			perfect = stage.first_perfect_funds if battle.is_perfect() and not profile.perfect_clear else 0
			_tip.text = "Provisional reward: %d Funds · Local balance: %d Funds" % [reward, _progress.snapshot().funds]
		else:
			_tip.text = "The clear could not be saved. Check local storage before retrying."
	operation_finished.emit({
		"stage_id": stage.stage_id,
		"title": %MissionTitle.text,
		"outcome": _outcome_label(),
		"integrity": battle.integrity,
		"defeated": battle.defeated,
		"escaped": battle.escaped,
		"clear_funds": first,
		"perfect_funds": perfect,
		"balance": _progress.snapshot().funds,
		"save_failed": failed,
	})
