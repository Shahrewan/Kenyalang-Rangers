class_name ProfileSettingsPage
extends VBoxContainer

signal back_requested
signal reset_requested

signal text_changed
signal help_requested

var preferences: PresentationAudio
var progress: CampaignProgress
var _feedback: Label
var _dialog: ConfirmationDialog

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	StoryUI.header(self, "Settings", func() -> void: back_requested.emit())
	var card := StoryUI.panel(StoryUI.scroll_column(self))
	for key: String in ["master", "music", "sfx"]:
		_add_slider(card, key)
	var text_size := OptionButton.new()
	text_size.name = "TextSize"
	for percent: int in [100, 115, 130]:
		text_size.add_item("Text size · %d%%" % percent, percent)
	text_size.select(text_size.get_item_index(preferences.values.text))
	text_size.item_selected.connect(func(index: int) -> void:
		if preferences.change("text", text_size.get_item_id(index)):
			text_changed.emit()
		else:
			text_size.select(text_size.get_item_index(preferences.values.text))
			_feedback.text = "Could not save text size. Check local storage."
	)
	card.add_child(text_size)
	var help := StoryUI.action("Help and references")
	help.pressed.connect(func() -> void: help_requested.emit())
	card.add_child(help)
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

func _add_slider(card: Container, key: String) -> void:
	var title := "Sound effects" if key == "sfx" else key.capitalize()
	var row := StoryUI.row(card)
	var label := StoryUI.label("%s · %d%%" % [title, preferences.values[key]], 20)
	label.custom_minimum_size.x = 240
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = key.capitalize() + "Volume"
	slider.accessibility_name = title
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.step = 5
	slider.value = preferences.values[key]
	slider.value_changed.connect(func(amount: float) -> void:
		if not preferences.change(key, roundi(amount)):
			slider.set_value_no_signal(preferences.values[key])
			_feedback.text = "Could not save volume. Check local storage."
		label.text = "%s · %d%%" % [title, preferences.values[key]]
		if key != "music":
			preferences.cue("confirm")
	)
	row.add_child(slider)

func _request_reset() -> void:
	_dialog.dialog_text = "Delete the Leader name, local progress, and its previous backup?"
	_dialog.popup_centered()

func show_error() -> void:
	_feedback.text = "Could not finish the reset. Check local storage and retry."

func request_back() -> void:
	if _dialog.visible:
		_dialog.hide()
	else:
		back_requested.emit()
