class_name HeadquartersOverview
extends VBoxContainer

signal back_requested
signal room_requested(room: HeadquartersRoom)
signal chaos_requested
signal tutorial_requested

const CHAOS_RECT := Rect2(167, 620, 280, 76)
const SCORE_RECT := Rect2(957, 618, 167, 64)

var progress: CampaignProgress
var _catalog: HeadquartersArt
var _scroll: ScrollContainer
var _stage: Control
var _shell: Node2D
var _canvas: Vector2
var _building_scale := 1.0
var _rooms: Dictionary[StringName, HeadquartersOfficeArt] = {}
var _targets: Dictionary[Control, Rect2] = {}
var _lobby: Node2D

func _ready() -> void:
	theme = HeadquartersArt.THEME
	add_theme_constant_override("separation", 6)
	var back := StoryUI.header(self, "Headquarters", func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	back.custom_minimum_size.y = 64
	var tutorial := StoryUI.action("HQ tutorial", true)
	tutorial.name = "OpenHeadquartersTutorial"
	tutorial.custom_minimum_size.y = 64
	tutorial.pressed.connect(func() -> void: tutorial_requested.emit())
	var header := back.get_parent()
	header.add_child(tutorial)
	header.move_child(tutorial, header.get_child_count() - 2)
	_catalog = HeadquartersArt.new()
	if _catalog.rooms.size() != CampaignProgress.HEADQUARTERS.rooms.size():
		_show_room_list()
		return
	_canvas = HeadquartersArt.point(_catalog.data.canvas_units)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	add_child(_scroll)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_PASS
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_stage)
	_shell = Node2D.new()
	_stage.add_child(_shell)
	var layers: Dictionary = _catalog.data.shell
	for layer: String in ["jungle", "roof", "frame_back", "lobby"]:
		HeadquartersArt.sprite(_shell, layers[layer], Rect2(Vector2.ZERO, _canvas), 0, layer)
	for room in CampaignProgress.HEADQUARTERS.rooms:
		_add_room(room)
	HeadquartersArt.sprite(_shell, _catalog.data.unbuilt, HeadquartersArt.rectangle(_catalog.data.vacant_bay), 0, "VacantBay")
	HeadquartersArt.sprite(_shell, layers.frame_front, Rect2(Vector2.ZERO, _canvas), 21, "frame_front")
	_add_lobby()
	HeadquartersArt.sprite(_shell, layers.foreground, Rect2(Vector2.ZERO, _canvas), 23, "foreground")
	_scroll.resized.connect(_fit)
	_stage.resized.connect(_layout_building)
	get_viewport().size_changed.connect(_fit)
	_fit.call_deferred()

func _add_room(room: HeadquartersRoom) -> void:
	var rect := HeadquartersArt.rectangle(_catalog.rooms[room.id].rect)
	var level := progress.room_level(room.id)
	var office := HeadquartersOfficeArt.new()
	office.name = "OfficeInterior"
	office.catalog = _catalog
	office.room_id = room.id
	office.level = level
	_stage.add_child(office)
	_rooms[room.id] = office
	_targets[office] = rect
	var button := _room_button(room)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", _outline(Color("#d4a860"), Color("#ffedb221")))
	button.add_theme_stylebox_override("pressed", _outline(Color("#f7d884"), Color("#ffedb248")))
	button.add_theme_stylebox_override("focus", _outline(Color("#fff1ae"), Color.TRANSPARENT))
	button.z_index = 24
	_stage.add_child(button)
	_targets[button] = rect

	var label_bar := PanelContainer.new()
	label_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := StyleBoxFlat.new()
	bar.bg_color = Color("#26332de8") if level > 0 else Color("#3e392de8")
	bar.set_corner_radius_all(3)
	bar.content_margin_left = 7
	bar.content_margin_right = 7
	label_bar.add_theme_stylebox_override("panel", bar)
	button.add_child(label_bar)
	label_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	label_bar.offset_left = 5
	label_bar.offset_right = -5
	label_bar.offset_top = 4
	var row := StoryUI.row(label_bar, 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := StoryUI.label(room.label, 17)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)
	var color := Color("#d9ebc3") if level > 0 else (StoryUI.AMBER if progress.room_quote(room.id).error.is_empty() else StoryUI.BEIGE)
	var state := StoryUI.label(_room_status(level), 16, color)
	state.name = "RoomLevel"
	state.autowrap_mode = TextServer.AUTOWRAP_OFF
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(state)

func _room_status(level: int) -> String:
	return "Lv.%d" % level if level > 0 else "Unbuilt"

func _room_button(room: HeadquartersRoom) -> Button:
	var button := StoryUI.action("")
	button.name = "Room_" + String(room.id).get_slice(".", 1)
	button.accessibility_name = "%s · %s" % [room.label, _room_status(progress.room_level(room.id))]
	button.tooltip_text = button.accessibility_name
	var error: String = progress.room_quote(room.id).error
	if progress.room_level(room.id) == 0 and not error.is_empty():
		button.tooltip_text += "\n" + error
	button.pressed.connect(func() -> void: room_requested.emit(room))
	return button

func _outline(stroke: Color, fill: Color) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.border_color = stroke
	frame.bg_color = fill
	frame.set_border_width_all(3)
	return frame

func _add_lobby() -> void:
	var best := progress.chaos_personal_best()
	var tier := ChaosScore.tier(best)
	var extent := Vector2.ONE * float(_catalog.data.trophy_max_size[1])
	var foot := HeadquartersArt.point(_catalog.data.trophy_anchor)
	var bounds := Rect2(foot - extent * Vector2(0.5, 154.0 / 160.0), extent)
	_lobby = Node2D.new()
	_lobby.name = "TrophyTier%d" % tier
	_shell.add_child(_lobby)
	if tier > 0:
		HeadquartersArt.sprite(_lobby, HeadquartersArt.TROPHIES + "tier_%d.png" % (tier * 1000), bounds, 22, "Emblem")
	HeadquartersArt.sprite(_lobby, HeadquartersArt.TROPHIES + "mount.png", bounds, 22, "Mount")
	var chaos := _chaos_button()
	chaos.z_index = 24
	_stage.add_child(chaos)
	_targets[chaos] = CHAOS_RECT
	var score := StoryUI.label("Personal best · %s" % StoryUI.funds(best), 18)
	score.name = "ChaosPersonalBest"
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score.add_theme_color_override("font_outline_color", Color("#26332d"))
	score.add_theme_constant_override("outline_size", 6)
	score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score.z_index = 24
	_stage.add_child(score)
	_targets[score] = SCORE_RECT

func _chaos_button() -> Button:
	var chaos := StoryUI.action("Rainforest Chaos →")
	chaos.name = "HeadquartersChaos"
	chaos.pressed.connect(func() -> void: chaos_requested.emit())
	return chaos

func _fit() -> void:
	if not is_inside_tree() or _scroll.size.x <= 0.0 or _scroll.size.y <= 0.0:
		return
	var fit := minf(_scroll.size.x / _canvas.x, _scroll.size.y / _canvas.y)
	var touch := StoryUI.android_touch_minimum(self)
	var target_height := minf(CHAOS_RECT.size.y, HeadquartersArt.rectangle(_catalog.data.rooms[0].rect).size.y)
	var required := maxf(touch.y / target_height, touch.x / CHAOS_RECT.size.x)
	_building_scale = maxf(fit, required)
	_stage.custom_minimum_size = _canvas * _building_scale
	_layout_building()

func _layout_building() -> void:
	var origin := ((_stage.size - _canvas * _building_scale) * 0.5).max(Vector2.ZERO)
	_shell.position = origin
	_shell.scale = Vector2.ONE * _building_scale
	for node: Control in _targets:
		var rect: Rect2 = _targets[node]
		node.position = origin + rect.position * _building_scale
		node.size = rect.size * _building_scale

func _show_room_list() -> void:
	var list := StoryUI.scroll_column(self)
	list.add_child(StoryUI.label("Headquarters artwork unavailable", 18, StoryUI.BEIGE))
	for room in CampaignProgress.HEADQUARTERS.rooms:
		var button := _room_button(room)
		button.text = button.accessibility_name
		list.add_child(button)
	list.add_child(_chaos_button())
