extends CenterContainer

signal name_submitted(value: String)

var feedback: Label

func _ready() -> void:
	var frame := StoryUI.panel(self, true)
	frame.custom_minimum_size.x = 430
	frame.add_child(StoryUI.label("Choose a Leader name", 32, StoryUI.INK))
	var input := LineEdit.new()
	input.name = "LeaderName"
	input.placeholder_text = "Leader name"
	input.max_length = 24
	input.custom_minimum_size.y = maxf(54.0, StoryUI.android_touch_minimum(self).y)
	frame.add_child(input)
	feedback = StoryUI.label("", 18, StoryUI.INK)
	frame.add_child(feedback)
	var proceed := StoryUI.action("Continue", true)
	proceed.name = "SaveName"
	proceed.disabled = true
	frame.add_child(proceed)
	input.text_changed.connect(func(value: String) -> void: proceed.disabled = value.strip_edges().is_empty())
	input.text_submitted.connect(func(value: String) -> void: name_submitted.emit(value))
	proceed.pressed.connect(func() -> void: name_submitted.emit(input.text))
	input.grab_focus()
