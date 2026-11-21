class_name BattleScene
extends Control

@export var stage: BattleStage
var campaign := false
var save_path := FirstContactProgress.DEFAULT_PATH
var _progress: FirstContactProgress
var _reported := false
var _tips := true

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
	_pause.pressed.connect(_toggle_pause)
	_speed.pressed.connect(_toggle_speed)
	_dialogue_button.pressed.connect(open_dialogue)
	_defeat.pressed.connect(_defeat_first)
	_retry.pressed.connect(_restart)
	%Continue.pressed.connect(close_dialogue)
	%Skip.pressed.connect(_skip_dialogue)
	if campaign:
		_progress = FirstContactProgress.new(save_path)
		%MissionTitle.text = "First Contact"
		%DialogueTitle.text = "First Contact"
		%DialogueText.text = (
			"Operations Manager: Our patrol spotted movement at the old chokepoint.\n\n"
			+ "Deploy the free Starter Post across two raised tiles. D01 yields 9 Tokens per 10 combat seconds.\n"
			+ "Place Scout Sniper on a raised tile near the bend. Place Patrolman on the path facing the entry.\n"
			+ "Rangers attack automatically. Keep Integrity above zero through both waves."
		)
		_opening.hide()
		_dialogue_button.hide()
		_defeat.hide()
		%DeploymentController.preview_skills = false
	_opening.add_item("First Contact")
	_opening.add_item("Normal loadout")
	_opening.add_item("D05 Fixed Stockpile")
	_opening.item_selected.connect(_change_opening)
	_restart()

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

func close_dialogue() -> void:
	if battle == null or not battle.clock.dialogue_open:
		return
	if not campaign:
		battle.record_cinematic_withdrawal()
	battle.clock.dialogue_open = false
	_refresh()
	if campaign:
		_pause.grab_focus()
	else:
		_dialogue_button.grab_focus()

func _skip_dialogue() -> void:
	_tips = false
	close_dialogue()

func _restart() -> void:
	var error := "No stage configured." if stage == null else stage.validation_error()
	if not error.is_empty():
		_status.text = error
		_pause.disabled = true
		_speed.disabled = true
		_dialogue_button.disabled = true
		_defeat.disabled = true
		_retry.disabled = true
		return
	battle = BattleSimulation.new(stage)
	_board.battle_map = stage.map
	_board.battle = battle
	%DeploymentController.setup(battle, stage.map)
	_reported = false
	_tips = true
	_tip.text = ""
	if campaign:
		battle.deployment = %DeploymentController.state
		_board.show_combat_hp = true
		open_dialogue()
	_refresh()

func _toggle_pause() -> void:
	battle.clock.paused = not battle.clock.paused
	_refresh()

func _toggle_speed() -> void:
	battle.clock.set_speed(3 - battle.clock.get_speed())
	_refresh()

func _defeat_first() -> void:
	if not battle.active.is_empty():
		battle.defeat_enemy(battle.active.keys()[0])
	_refresh()

func _refresh() -> void:
	var opening_label := String(stage.stage_id)
	if _opening.selected == 1:
		opening_label = "Normal fixture"
	elif _opening.selected == 2:
		opening_label = "D05 fixture"
	var label := "%s · Wave %d/%d" % [opening_label, battle.wave_number, battle.wave_count]
	match battle.outcome:
		BattleSimulation.Outcome.WON:
			label = "Perfect clear" if battle.is_perfect() else "Clear"
		BattleSimulation.Outcome.LOST:
			label = "Defeat"
	_status.text = "%s   ·   Integrity %d   ·   Defeated %d   ·   Escaped %d" % [
		label, battle.integrity, battle.defeated, battle.escaped,
	]
	if campaign:
		_update_campaign_tip()
	var clock := battle.clock
	_pause.text = "Resume" if clock.paused else "Pause"
	_speed.text = "%d×" % clock.get_speed()
	_back.disabled = clock.dialogue_open
	_pause.disabled = clock.stopped or clock.dialogue_open
	_speed.disabled = clock.stopped or clock.dialogue_open
	_dialogue_button.disabled = clock.stopped or clock.dialogue_open
	_defeat.disabled = not clock.is_running() or battle.active.is_empty()
	_retry.disabled = clock.dialogue_open
	_opening.disabled = clock.dialogue_open
	_dialogue.visible = clock.dialogue_open
	_board.queue_redraw()

func _update_campaign_tip() -> void:
	if battle.outcome != BattleSimulation.Outcome.RUNNING:
		if _reported:
			return
		_reported = true
		if battle.outcome == BattleSimulation.Outcome.LOST:
			_tip.text = "Integrity reached zero. Restart to retry First Contact with the same supply."
		else:
			var reward := _progress.record_clear(battle.is_perfect(), stage.first_clear_funds, stage.first_perfect_funds)
			if reward >= 0:
				_tip.text = "Provisional reward: %d Funds · Local balance: %d Funds" % [reward, _progress.snapshot().funds]
			else:
				_tip.text = "The clear could not be saved. Check local storage before retrying."
		return
	if not _tips:
		_tip.text = ""
	elif battle.deployment.posts_deployed == 0:
		_tip.text = "Drag the free Starter Post onto two raised tiles."
	elif battle.deployment.placed.size() < 3:
		_tip.text = "Cover the bend with Scout. Block the lower path with a left-facing Patrolman."
	else:
		_tip.text = "Hold a Ranger to retreat. Pause to review the field."
