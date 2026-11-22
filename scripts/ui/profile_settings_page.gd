class_name ProfileSettingsPage
extends VBoxContainer

signal back_requested
signal reset_requested

var progress: CampaignProgress
var _feedback: Label
var _dialog: ConfirmationDialog

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	StoryUI.header(self, "Settings", func() -> void: back_requested.emit())
	var card := StoryUI.panel(StoryUI.scroll_column(self))
	card.add_child(StoryUI.label("Local progress", 26, StoryUI.AMBER))
	var details := progress.load_notice
	if details.is_empty():
		details = "This device stores the Leader name, Campaign, Headquarters, and activity progress."
	card.add_child(StoryUI.label(details, 21))
	var reset := StoryUI.action("Reset local progress")
	reset.name = "ResetProgress"
	reset.pressed.connect(_request_reset)
	card.add_child(reset)
	_feedback = StoryUI.label("", 19, StoryUI.AMBER)
	card.add_child(_feedback)
	_dialog = StoryUI.confirmation(self, "Reset local progress", "Delete progress")
	_dialog.confirmed.connect(func() -> void: reset_requested.emit())

func _request_reset() -> void:
	_dialog.dialog_text = "Delete the Leader name, local progress, and its previous backup?"
	_dialog.popup_centered()

func show_error() -> void:
	_feedback.text = "Could not finish the reset. Check local storage and retry."
