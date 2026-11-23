class_name BattlePauseOverlay
extends ColorRect

signal resume_requested
signal abandon_requested
signal settings_requested
signal controls_requested

var _intel: WaveIntel
var _active: Label
var _pause_view: VBoxContainer
var _confirm_view: VBoxContainer
var _resume: Button
var _cancel: Button
var _abandon: Button
var _confirm_message: Label
var _options: HBoxContainer

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := StoryUI.panel(center)
	box.custom_minimum_size.x = 560
	_pause_view = StoryUI.column(box)
	_pause_view.add_child(StoryUI.label("Operation paused", 32))
	_active = StoryUI.label("", 18, StoryUI.BEIGE)
	_pause_view.add_child(_active)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 236
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_view.add_child(scroll)
	_intel = WaveIntel.new()
	_intel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_intel)
	var controls := StoryUI.row(_pause_view)
	_resume = StoryUI.action("Resume", true)
	_resume.name = "ResumeOperation"
	_resume.pressed.connect(func() -> void: resume_requested.emit())
	controls.add_child(_resume)
	_abandon = StoryUI.action("Abandon operation")
	_abandon.name = "AskAbandon"
	_abandon.pressed.connect(_show_confirmation)
	controls.add_child(_abandon)
	_options = StoryUI.row(_pause_view)
	var help := StoryUI.action("Controls")
	help.name = "PauseControls"
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help.pressed.connect(func() -> void: controls_requested.emit())
	_options.add_child(help)
	var settings := StoryUI.action("Settings")
	settings.name = "PauseSettings"
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(func() -> void: settings_requested.emit())
	_options.add_child(settings)

	_confirm_view = StoryUI.column(box)
	_confirm_view.add_child(StoryUI.label("Abandon this operation?", 30))
	_confirm_message = StoryUI.label("", 20)
	_confirm_view.add_child(_confirm_message)
	var confirm_controls := StoryUI.row(_confirm_view)
	_cancel = StoryUI.action("Keep playing", true)
	_cancel.name = "CancelAbandon"
	_cancel.pressed.connect(_cancel_confirmation)
	confirm_controls.add_child(_cancel)
	var leave := StoryUI.action("Abandon")
	leave.name = "ConfirmAbandon"
	leave.pressed.connect(func() -> void: abandon_requested.emit())
	confirm_controls.add_child(leave)
	_confirm_view.hide()

func show_battle(stage: BattleStage, battle: BattleSimulation, can_abandon: bool, can_open_options: bool) -> void:
	_intel.show_stage(stage, battle)
	_active.text = "Wave %d/%d   ·   %d active" % [battle.wave_number, battle.wave_count, battle.active.size()]
	_abandon.visible = can_abandon
	_options.visible = can_open_options
	show()
	_cancel_confirmation()
	StoryUI.size_buttons(self)

func request_back() -> void:
	if _confirm_view.visible:
		_cancel_confirmation()
	else:
		resume_requested.emit()

func show_abandon_error() -> void:
	_confirm_message.text = "Could not save. Check local storage and retry Abandon."

func _show_confirmation() -> void:
	_confirm_message.text = "Return to your plan without earning Funds."
	_pause_view.hide()
	_confirm_view.show()
	_cancel.grab_focus()

func _cancel_confirmation() -> void:
	_confirm_view.hide()
	_pause_view.show()
	_resume.grab_focus()
