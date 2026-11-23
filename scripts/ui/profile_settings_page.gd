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
var _text_buttons: Dictionary[int, Button] = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	StoryUI.header(self, "Settings", request_back)
	var card := StoryUI.panel(StoryUI.scroll_column(self))
	for key: String in ["master", "music", "sfx"]:
		_add_slider(card, key)
	_add_text_sizes(card)
	var help := StoryUI.action("Help and references")
	help.pressed.connect(func() -> void: help_requested.emit())
	card.add_child(help)
	if progress != null:
		_add_progress_controls(card)
	_feedback = StoryUI.label("", 19, StoryUI.AMBER)
	card.add_child(_feedback)

func _add_text_sizes(card: Container) -> void:
	card.add_child(StoryUI.label("Text size", 20))
	var sizes := StoryUI.row(card, 8)
	var group := ButtonGroup.new()
	for percent: int in PresentationAudio.TEXT_SIZES:
		var button := StoryUI.action("%d%%" % percent)
		button.name = "TextSize%d" % percent
		button.accessibility_name = "Text size %d percent" % percent
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_pressed_no_signal(percent == preferences.values.text)
		button.pressed.connect(_set_text_size.bind(percent))
		_text_buttons[percent] = button
		sizes.add_child(button)

func _set_text_size(percent: int) -> void:
	if preferences.change("text", percent):
		_feedback.text = ""
		text_changed.emit()
	else:
		_text_buttons[preferences.values.text].set_pressed_no_signal(true)
		_feedback.text = "Could not save text size. Check local storage."

func _add_progress_controls(card: Container) -> void:
	card.add_child(StoryUI.label("Local progress", 26, StoryUI.AMBER))
	var details := progress.load_notice
	if details.is_empty():
		details = "This device stores the Leader name, Campaign, Headquarters, and activity progress."
	card.add_child(StoryUI.label(details, 21))
	var reset := StoryUI.action("Reset local progress")
	reset.name = "ResetProgress"
	reset.pressed.connect(_request_reset)
	card.add_child(reset)
	_dialog = StoryUI.confirmation(self, "Reset local progress", "Delete progress")
	_dialog.confirmed.connect(func() -> void: reset_requested.emit())

func _add_slider(card: Container, key: String) -> void:
	var title := "Sound effects" if key == "sfx" else key.capitalize()
	var row := StoryUI.row(card)
	var label := StoryUI.label(title, 20)
	label.custom_minimum_size.x = 196
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(label)
	var value := StoryUI.label("%d%%" % preferences.values[key], 20)
	value.custom_minimum_size.x = 82
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
			return
		_feedback.text = ""
		value.text = "%d%%" % preferences.values[key]
		if key != "music":
			preferences.cue("confirm")
	)
	row.add_child(slider)
	row.add_child(value)

func _request_reset() -> void:
	_dialog.dialog_text = "Delete the Leader name, local progress, and its previous backup?"
	_dialog.popup_centered()

func show_error() -> void:
	_feedback.text = "Could not finish the reset. Check local storage and retry."

func request_back() -> void:
	if _dialog != null and _dialog.visible:
		_dialog.hide()
	else:
		back_requested.emit()
