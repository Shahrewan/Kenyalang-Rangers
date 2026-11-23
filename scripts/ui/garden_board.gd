class_name GardenBoard
extends Control

signal plot_selected(slot: int)

const ART_ROOT := "res://assets/imported/restoration/"
# Coordinate space and pivots from the W19b restoration art manifest.
const ART_SIZE := Vector2(1200, 800)
const PLOTS := [Vector2(281, 347), Vector2(600, 347), Vector2(919, 347), Vector2(281, 618), Vector2(600, 618), Vector2(919, 618)]
const STAGE_NAMES := [&"", &"seed", &"sapling", &"mature"]
const EFFECT_FRAMES := {"water": [0.09, 0.09, 0.10, 0.14], "collect": [0.10, 0.10, 0.10, 0.16]}
const VISITOR_SECONDS := 1.65

var _buttons: Array[Button] = []
var _textures: Dictionary[String, Texture2D] = {}
var _state: Dictionary
var _now: int
var _capacity: int
var _scale := 1.0
var _origin := Vector2.ZERO
var _active_effect := ""
var _effect_slot: int
var _effect_elapsed: float
var _effect_tween: Tween
var _visitor_elapsed := VISITOR_SECONDS

func _ready() -> void:
	custom_minimum_size = Vector2(535, 380)
	clip_contents = true
	var group := ButtonGroup.new()
	for slot in PLOTS.size():
		var button := StoryUI.action("")
		button.name = "Plot%d" % (slot + 1)
		button.add_theme_font_size_override("font_size", 18)
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(func() -> void: plot_selected.emit(slot))
		button.minimum_size_changed.connect(_layout_buttons)
		add_child(button)
		_buttons.append(button)
	resized.connect(_layout_buttons)
	_layout_buttons()

func present(state: Dictionary, now: int, capacity: int, selected: int) -> void:
	_state = state
	_now = now
	_capacity = capacity
	for slot in _buttons.size():
		var plot: Dictionary = state.plots.get(RestorationRules.plot_id(slot), {})
		var caption := "Growing"
		if slot >= _capacity:
			caption = "Locked"
		elif plot.is_empty():
			caption = "Plant"
		elif RestorationRules.needs_water(plot, now):
			caption = "Water"
		elif RestorationRules.stage(plot, now) == RestorationRules.Stage.MATURE:
			caption = "Collect"
		_buttons[slot].text = "%d · %s" % [slot + 1, caption]
		_buttons[slot].tooltip_text = "Plot %d · %s" % [slot + 1, caption]
		_buttons[slot].set_pressed_no_signal(slot == selected)
	_layout_buttons()

func play_effect(effect: String, slot: int, visitor := false) -> void:
	if _effect_tween != null:
		_effect_tween.kill()
	_active_effect = effect
	_effect_slot = slot
	_effect_elapsed = 0.0
	var duration: float = 0.0
	for seconds: float in EFFECT_FRAMES[effect]:
		duration += seconds
	_effect_tween = create_tween()
	_effect_tween.tween_method(_advance_effect, 0.0, duration, duration)
	_effect_tween.tween_callback(func() -> void:
		_active_effect = ""
		queue_redraw()
	)
	if visitor:
		_visitor_elapsed = 0.0
		create_tween().tween_method(_advance_visitor, 0.0, VISITOR_SECONDS, VISITOR_SECONDS)

func _advance_effect(elapsed: float) -> void:
	_effect_elapsed = elapsed
	queue_redraw()

func _advance_visitor(elapsed: float) -> void:
	_visitor_elapsed = elapsed
	queue_redraw()

func _layout_buttons() -> void:
	_scale = maxf(0.01, minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y))
	_origin = (size - ART_SIZE * _scale) * 0.5
	for slot in _buttons.size():
		var button := _buttons[slot]
		button.size = button.get_combined_minimum_size()
		button.position = _origin + (PLOTS[slot] + Vector2(0.0, 85.0)) * _scale - button.size * 0.5
	queue_redraw()

func _draw() -> void:
	if _state.is_empty():
		return
	draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
	_draw_art("garden_clearing.jpg", Vector2.ZERO, Vector2.ZERO, ART_SIZE, 1.0, "Garden art placeholder")
	for slot in PLOTS.size():
		var id := RestorationRules.plot_id(slot)
		var anchor: Vector2 = PLOTS[slot]
		var factor := 0.82 if slot < 3 else 0.90
		var tint := Color.WHITE if slot < _capacity else Color(0.62, 0.62, 0.58, 0.8)
		_draw_art("plot_bed.png", anchor, Vector2(160, 133), Vector2(320, 208), factor, "Plot placeholder", tint)
		var plot: Dictionary = _state.plots.get(id, {})
		if _state.scenery.has(id):
			var beside := Vector2(-88, -31) if not plot.is_empty() else Vector2.ZERO
			_draw_tree(_state.scenery[id], &"mature", anchor + beside, factor * (0.68 if not plot.is_empty() else 1.0))
		if not plot.is_empty():
			_draw_tree(plot.species, STAGE_NAMES[RestorationRules.stage(plot, _now)], anchor, factor)
	_draw_art("hornbill_guide.png", Vector2(1116, 746), Vector2(132, 192), Vector2(256, 256), 0.48, "Guide")
	if _state.nest_box_seen:
		_draw_art("nest_box.png", Vector2(1154, 164), Vector2(83, 81), Vector2(160, 160), 0.72, "Nest box")
	if _visitor_elapsed < VISITOR_SECONDS:
		var flight := _visitor_elapsed / VISITOR_SECONDS
		var perch := Vector2(27, 155).lerp(Vector2(1077, 142), flight) + Vector2(0, -100 * sin(PI * flight))
		_draw_art("hornbill_visitor.png", perch, Vector2(133, 133), Vector2(256, 256), 0.58, "Visitor")
	if not _active_effect.is_empty():
		_draw_effect()

func _draw_tree(species: String, stage: StringName, anchor: Vector2, factor: float) -> void:
	var file := "trees/%s/%s.png" % [species.get_slice(".", 1), stage]
	_draw_art(file, anchor, Vector2(128, 224), Vector2(256, 256), factor, "%s placeholder" % String(stage).capitalize())

func _draw_effect() -> void:
	var t := _effect_elapsed
	var frame := 0
	for duration: float in EFFECT_FRAMES[_active_effect]:
		if t < duration:
			break
		t -= duration
		frame += 1
	var texture := _texture("effects/%s.png" % _active_effect)
	if texture != null and frame < 4:
		var dest := Rect2(PLOTS[_effect_slot] - Vector2(64, 96), Vector2(128, 128))
		draw_texture_rect_region(texture, dest, Rect2(Vector2(128 * frame, 0), dest.size))

func _draw_art(file: String, anchor: Vector2, pivot: Vector2, pixels: Vector2, factor: float, fallback: String, tint := Color.WHITE) -> void:
	var bounds := Rect2(anchor - pivot * factor, pixels * factor)
	var texture := _texture(file)
	if texture != null:
		draw_texture_rect(texture, bounds, false, tint)
	else:
		draw_rect(bounds, StoryUI.INK)
		draw_string(ThemeDB.fallback_font, bounds.position + Vector2(9, 34), fallback, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, StoryUI.CREAM)

func _texture(file: String) -> Texture2D:
	if not _textures.has(file):
		var path := ART_ROOT + file
		_textures[file] = load(path) as Texture2D if ResourceLoader.exists(path, "Texture2D") else null
	return _textures[file]
