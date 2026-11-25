class_name StoryUI
extends RefCounted

const INK := Color("#343D32")
const CREAM := Color("#F3EBDD")
const BEIGE := Color("#D6C8AD")
const AMBER := Color("#E8B957")
const TOUCH_MINIMUM := Vector2(52, 52)

static func label(text: String, font_size := 20, color := CREAM) -> Label:
	var view := Label.new()
	view.text = text
	view.add_theme_font_size_override("font_size", font_size)
	view.add_theme_color_override("font_color", color)
	view.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return view

static func action(text: String, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	# Allow enclosing scrollers to take over when a finger moves beyond the deadzone.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size = TOUCH_MINIMUM
	if primary:
		button.theme_type_variation = &"PrimaryButton"
	return button

static func artwork(texture: Texture2D, extent: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = extent
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

static func column(parent: Node, gap := 12) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	parent.add_child(box)
	return box

static func row(parent: Node, gap := 12) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	parent.add_child(box)
	return box

static func panel(parent: Node, light := false) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if light:
		frame.theme_type_variation = &"LightPanel"
	parent.add_child(frame)
	return column(frame)

static func scroll_column(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 12
	scroll.follow_focus = true
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var content := column(scroll, 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return content

static func header(parent: Node, title: String, back: Callable, summary := "") -> Button:
	var line := row(parent, 20)
	var back_button := action("Back")
	line.add_child(back_button)
	back_button.pressed.connect(back)
	var heading := label(title, 32)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(heading)
	if not summary.is_empty():
		var balance := label(summary, 19, BEIGE)
		balance.name = "FundsSummary"
		balance.autowrap_mode = TextServer.AUTOWRAP_OFF
		line.add_child(balance)
	return back_button

static func android_touch_minimum(control: Control) -> Vector2:
	if not OS.has_feature("android"):
		return TOUCH_MINIMUM
	var density := float(DisplayServer.screen_get_dpi()) / 160.0
	var transform := control.get_viewport().get_screen_transform()
	var scale := Vector2(transform.x.length(), transform.y.length())
	return TOUCH_MINIMUM.max((Vector2.ONE * ceilf(48.0 * density) / scale.max(Vector2(0.01, 0.01))).ceil())

static func funds(amount: int) -> String:
	var digits := str(absi(amount))
	var parts := PackedStringArray()
	while digits.length() > 3:
		parts.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	parts.insert(0, digits)
	return ("−" if amount < 0 else "") + ",".join(parts)

static func confirmation(parent: Control, title: String, caption: String) -> ConfirmationDialog:
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.ok_button_text = caption
	parent.add_child(dialog)
	var minimum := android_touch_minimum(parent)
	dialog.get_ok_button().custom_minimum_size = minimum
	dialog.get_cancel_button().custom_minimum_size = minimum
	return dialog

static func size_buttons(page: Control) -> void:
	if not page.is_inside_tree():
		return
	var minimum := android_touch_minimum(page)
	for item in page.find_children("*", "BaseButton", true, false):
		var button := item as BaseButton
		button.custom_minimum_size = button.custom_minimum_size.max(minimum)
