class_name BattleScene
extends Control

@export var stage: BattleStage

@onready var _board: BattleBoard = %Board
@onready var _status: Label = %Status
@onready var _back: Button = %BackToMenu
@onready var _pause: Button = %Pause
@onready var _speed: Button = %Speed
@onready var _dialogue_button: Button = %OpenDialogue
@onready var _defeat: Button = %DefeatEnemy
@onready var _retry: Button = %Retry
@onready var _dialogue: ColorRect = %Dialogue

var battle: BattleSimulation

func _ready() -> void:
	_pause.pressed.connect(_toggle_pause)
	_speed.pressed.connect(_toggle_speed)
	_dialogue_button.pressed.connect(open_dialogue)
	_defeat.pressed.connect(_defeat_first)
	_retry.pressed.connect(_restart)
	%Continue.pressed.connect(close_dialogue)
	%Skip.pressed.connect(close_dialogue)
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
	battle.record_cinematic_withdrawal()
	battle.clock.dialogue_open = false
	_refresh()
	_dialogue_button.grab_focus()

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
	var label := "%s · Wave %d/%d" % [stage.stage_id, battle.wave_number, battle.wave_count]
	match battle.outcome:
		BattleSimulation.Outcome.WON:
			label = "Perfect clear" if battle.is_perfect() else "Clear"
		BattleSimulation.Outcome.LOST:
			label = "Defeat"
	_status.text = "%s   ·   Integrity %d   ·   Defeated %d   ·   Escaped %d" % [
		label, battle.integrity, battle.defeated, battle.escaped,
	]
	var clock := battle.clock
	_pause.text = "Resume" if clock.paused else "Pause"
	_speed.text = "%d×" % clock.get_speed()
	_back.disabled = clock.dialogue_open
	_pause.disabled = clock.stopped or clock.dialogue_open
	_speed.disabled = clock.stopped or clock.dialogue_open
	_dialogue_button.disabled = clock.stopped or clock.dialogue_open
	_defeat.disabled = not clock.is_running() or battle.active.is_empty()
	_retry.disabled = clock.dialogue_open
	_dialogue.visible = clock.dialogue_open
	_board.queue_redraw()
