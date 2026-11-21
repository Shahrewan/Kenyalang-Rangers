extends MarginContainer

const PADDING := 24

func _ready() -> void:
	get_viewport().size_changed.connect(_update_margins)
	_update_margins()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_node_ready():
		_update_margins.call_deferred()

func _update_margins() -> void:
	var margins := Vector4i.ONE * PADDING
	if OS.has_feature("android"):
		var window := get_window()
		var safe := Rect2(DisplayServer.get_display_safe_area())
		safe.position -= Vector2(window.position)
		var viewport_bounds := get_viewport_rect()
		margins = safe_margins(viewport_bounds, safe, get_viewport().get_screen_transform())

	add_theme_constant_override("margin_left", margins.x)
	add_theme_constant_override("margin_top", margins.y)
	add_theme_constant_override("margin_right", margins.z)
	add_theme_constant_override("margin_bottom", margins.w)

# Window safe bounds are in physical pixels, while margins use logical coordinates.
static func safe_margins(bounds: Rect2, safe_pixels: Rect2, viewport_to_window: Transform2D) -> Vector4i:
	var safe := bounds.intersection(viewport_to_window.affine_inverse() * safe_pixels)
	if not safe.has_area():
		return Vector4i.ONE * PADDING

	return Vector4i(
		ceili(safe.position.x - bounds.position.x) + PADDING,
		ceili(safe.position.y - bounds.position.y) + PADDING,
		ceili(bounds.end.x - safe.end.x) + PADDING,
		ceili(bounds.end.y - safe.end.y) + PADDING
	)
