extends Control

# Review fixture for the visual kit. Example state stays in this preview.
# Nothing in this tree obtains a writable campaign profile.
const SKIN := preload("res://resources/presentation/w29_ui_theme.tres")
const UI := "res://assets/imported/ui/w29/"
const C28 := "res://assets/imported/first_contact/"
const GARDEN := "res://assets/imported/restoration/"
const FIELD := C28 + "t01_forest_backdrop.jpg"
const FUNDS_ICON := UI + "icons/light/finance.svg"
const C28_INTERFACE := C28 + "parts/interface/"
const C28_BADGES := C28 + "parts/badges/"
const ROOMS := preload("res://data/headquarters/rooms.tres")
const TOUCH := 64.0
const EDGE := 24
const PAGE_NAMES := {
	"home": "Kenyalang Rangers",
	"naming": "Name your Leader",
	"story": "Story Mode",
	"plan": "Operation plan",
	"loadout": "Select Rangers",
	"facility_loadout": "Select Facilities",
	"modifiers": "Operation modifiers",
	"pause": "Operation paused",
	"abandon": "Abandon operation?",
	"result": "Operation report",
	"settings": "Settings",
	"reset": "Reset local progress?",
	"headquarters": "Headquarters",
	"room": "Mechanical",
	"research": "Research & Development",
	"roster": "Ranger catalogue",
	"unit": "Scout Sniper",
	"chaos_routes": "Rainforest Chaos",
	"chaos_composer": "Configure run",
	"chaos_result": "Chaos report",
	"garden": "Habitat Restoration",
	"seeds": "Plant a seed",
	"outreach": "Outreach",
	"records": "Records",
	"quiz": "Field Identification",
	"guide": "Field Guide",
}
const ROOM_ICONS := ["control", "human_resources", "finance", "mechanical", "ecology",
	"outreach", "records", "ecology", "attack", "defense", "warning"]
const SPECIES := [
	["belian", "Belian", "18 h"], ["mengaris", "Mengaris", "48 h"],
	["red_meranti", "Meranti Merah", "36 h"], ["strangler_fig", "Strangler Fig", "72 h"],
]
const HUB_FALLBACK := "res://assets/imported/hq/"
const REGIONS := ["Forgotten Patrol", "Gunung Mulu", "Batang Ai", "Tanjung Datu",
	"Imbak Canyon", "Sepilok-Kabili"]

var active_page: String = "home"
var zoom: float = 1.0
var balance: String = "20,000"
var selected_room_id: StringName = &"room.mechanical"
var selected_chaos_region := 0
var history: Array[String] = []
var _surface: Control
var _content: VBoxContainer
var _body: VBoxContainer
var _foot: HBoxContainer


func _ready() -> void:
	theme = SKIN
	show_page("home")


func show_page(id: String, track := false) -> void:
	assert(PAGE_NAMES.has(id), id)
	if track and id != active_page:
		history.append(active_page)
	if is_instance_valid(_surface):
		remove_child(_surface)
		_surface.queue_free()
	active_page = id
	_surface = Control.new()
	_surface.name = "Preview_" + id
	add_child(_surface)
	_surface.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if id == "home":
		_home()
		return
	if id == "naming":
		_name()
		return
	if id in ["pause", "abandon", "reset"]:
		_modal(id)
		return
	_make_shell(_visible_title(id), id not in ["guide", "settings"])
	match id:
		"story": _story()
		"plan": _plan()
		"loadout", "facility_loadout": _loadout(id == "facility_loadout")
		"modifiers": _modifiers()
		"result", "chaos_result": _result(id == "chaos_result")
		"settings": _settings()
		"headquarters": _headquarters()
		"room": _room()
		"research": _research()
		"roster": _roster()
		"unit": _unit()
		"chaos_routes": _chaos_routes()
		"chaos_composer": _chaos_composer()
		"garden": _garden()
		"seeds": _seeds()
		"outreach": _outreach()
		"records": _records()
		"quiz": _quiz()
		"guide": _guide()


func _visible_title(id: String) -> String:
	if id == "room":
		for room: HeadquartersRoom in ROOMS.rooms:
			if room.id == selected_room_id:
				return room.label
	return PAGE_NAMES[id]


func open_page(id: String) -> void:
	show_page(id, true)


func go_back() -> void:
	show_page("home" if history.is_empty() else history.pop_back())


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()
		get_viewport().set_input_as_handled()


func _backdrop(host: Control, path := "", color := Color("#253127")) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = color
	backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	host.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if not path.is_empty():
		var scene := _photo(host, path, Vector2.ZERO, true)
		scene.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		var shade := ColorRect.new()
		shade.color = Color("#17231dcc")
		shade.mouse_filter = MOUSE_FILTER_IGNORE
		host.add_child(shade)
		shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)


func _safe(host: Control, margin: int) -> MarginContainer:
	var safe := MarginContainer.new()
	host.add_child(safe)
	safe.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		safe.add_theme_constant_override("margin_" + side, margin)
	return safe


func _decorate(host: Control, top_y: float) -> void:
	var leaves := _photo(host, UI + "brand/fern.svg", Vector2.ZERO, false)
	leaves.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	leaves.offset_left = -188
	leaves.offset_top = top_y
	leaves.offset_right = -18
	leaves.offset_bottom = -6
	leaves.modulate = Color(1.0, 1.0, 1.0, 0.30)


func _make_shell(title: String, show_funds: bool) -> void:
	_backdrop(_surface)
	_decorate(_surface, -155)
	_content = _column(_safe(_surface, EDGE), 14)
	_header(_content, title, show_funds)
	_body = _scroll(_content, 12)
	_body.size_flags_vertical = SIZE_EXPAND_FILL
	_foot = _row(_content, 12)
	_foot.hide()


func _header(host: Control, title: String, show_funds: bool) -> void:
	var band := _card(host, "FieldPanel", 0)
	var line := _row(band, 16)
	band.get_parent().size_flags_horizontal = SIZE_EXPAND_FILL
	var back := _button(line, "Back", "", "back", "NavButton")
	back.pressed.connect(go_back)
	var name_label := _label(line, title, "FieldTitle")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	if show_funds:
		_chip(line, balance + " Funds", FUNDS_ICON)


func _button(parent: Control, caption: String, route: String = "", symbol: String = "",
		variant := "Button", enabled := true) -> Button:
	var result := Button.new()
	result.text = caption
	result.theme_type_variation = &"" if variant == "Button" else StringName(variant)
	result.custom_minimum_size.y = TOUCH
	result.custom_minimum_size.x = TOUCH
	result.disabled = not enabled
	result.add_theme_font_size_override("font_size", roundi(19 * zoom))
	if not symbol.is_empty():
		var family := "light" if variant in ["NavButton", "DangerButton"] or not enabled else "dark"
		result.icon = _texture(UI + "icons/%s/%s.svg" % [family, symbol])
		result.set_meta("preview_icon", UI + "icons/%s/%s.svg" % [family, symbol])
	if not route.is_empty() and enabled:
		result.set_meta("preview_route", route)
		result.pressed.connect(open_page.bind(route))
	parent.add_child(result)
	return result


func _label(parent: Control, caption: String, variant: String = "FieldMeta", explicit := 0) -> Label:
	var result := Label.new()
	result.text = caption
	result.theme_type_variation = StringName(variant)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if caption.length() > 38 else TextServer.AUTOWRAP_OFF
	var font_size := explicit if explicit > 0 else SKIN.get_font_size("font_size", variant)
	result.add_theme_font_size_override("font_size", roundi(font_size * zoom))
	result.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


func _row(parent: Control, gap: int = 12) -> HBoxContainer:
	var result := HBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	parent.add_child(result)
	return result


func _column(parent: Control, gap: int = 12) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	parent.add_child(result)
	return result


func _card(parent: Control, style: String = "PanelContainer", gap: int = 10) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"" if style == "PanelContainer" else StringName(style)
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(panel)
	return _column(panel, gap)


func _scroll(parent: Control, gap: int = 11) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var contents := _column(scroll, gap)
	contents.size_flags_horizontal = SIZE_EXPAND_FILL
	contents.size_flags_vertical = SIZE_EXPAND_FILL
	return contents


func _photo(parent: Control, path: String, minimum: Vector2, cover: bool) -> TextureRect:
	var view := TextureRect.new()
	view.texture = _texture(path)
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.custom_minimum_size = minimum
	view.mouse_filter = MOUSE_FILTER_IGNORE
	view.clip_contents = true
	if view.texture != null:
		view.set_meta("preview_texture", path)
	parent.add_child(view)
	return view


func _texture(path: String) -> Texture2D:
	if not path.is_empty() and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _media(options: Array[String], fallback: String) -> String:
	for path in options:
		if ResourceLoader.exists(path):
			return path
	return fallback


func _chip(parent: Control, value: String, path: String = "", paper := false) -> void:
	var box := _card(parent, "BrassPanel" if paper else "PanelContainer", 0)
	var frame := box.get_parent() as PanelContainer
	frame.size_flags_horizontal = SIZE_SHRINK_CENTER
	if not path.is_empty():
		var line := _row(box, 8)
		_photo(line, path, Vector2(22, 22), false)
		_label(line, value, "PaperMeta" if paper else "FieldMeta")
	else:
		_label(box, value, "PaperMeta" if paper else "FieldMeta")


func _gap(parent: Control, axis := false) -> void:
	var space := Control.new()
	if axis:
		space.size_flags_vertical = SIZE_EXPAND_FILL
	else:
		space.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(space)


func _action(caption: String, route: String, symbol: String = "forward", variant: String = "PrimaryButton") -> Button:
	_foot.show()
	_gap(_foot)
	return _button(_foot, caption, route, symbol, variant)


func _tabs(parent: Control, rows: Array, selected: String) -> void:
	var strip := _row(parent, 10)
	for item: Array in rows:
		var control := _button(strip, item[0], item[1], item[2], "NavButton" if item[1] == selected else "Button")
		control.size_flags_horizontal = SIZE_EXPAND_FILL


func _meter(parent: Control, numerator: float, denominator: float, danger := false) -> void:
	var value := ProgressBar.new()
	value.theme_type_variation = &"DangerMeter" if danger else &""
	value.max_value = denominator
	value.value = numerator
	value.show_percentage = false
	value.custom_minimum_size.y = 17
	value.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(value)


func _home() -> void:
	_backdrop(_surface, FIELD)
	var root := _column(_safe(_surface, EDGE), 14)
	var identity := _row(root, 15)
	_photo(identity, UI + "brand/hornbill.svg", Vector2(90, 66), false)
	var wordmark := _label(identity, "Kenyalang Rangers", "FieldTitle", 47)
	wordmark.size_flags_horizontal = SIZE_EXPAND_FILL
	var player := _card(identity, "FieldPanel", 5)
	player.get_parent().size_flags_horizontal = SIZE_SHRINK_CENTER
	_label(player, "Leader Rimba", "FieldStrong", 17)
	var funds := _row(player, 7)
	_photo(funds, FUNDS_ICON, Vector2(18, 18), false)
	_label(funds, balance + " Funds", "FieldMeta")
	var cards := _row(_scroll(root, 0), 16)
	cards.size_flags_vertical = SIZE_EXPAND_FILL
	var hq := _card(cards, "LightPanel", 8)
	hq.get_parent().size_flags_stretch_ratio = 1.45
	var display := _photo(hq, _hq_art(), Vector2(0, 130), true)
	display.size_flags_vertical = SIZE_EXPAND_FILL
	_label(hq, "Headquarters", "PaperTitle")
	_label(hq, "Manage rooms, crews and research", "PaperMeta")
	_button(hq, "Open Headquarters", "headquarters", "headquarters", "PrimaryButton")
	var operations := _column(cards, 12)
	operations.size_flags_horizontal = SIZE_EXPAND_FILL
	_home_mode(operations, "Story Mode", "First Contact · T01", "story", "campaign", FIELD)
	_home_mode(operations, "Rainforest Chaos", "Custom waves and Medal Score", "chaos_routes", "chaos",
		_media(["res://assets/imported/environments/t02/backdrop.jpg",
			"res://assets/imported/environments/t02/backdrop.png"], FIELD))
	var bottom := _row(root, 12)
	_button(bottom, "Reforestation", "garden", "restoration").size_flags_horizontal = SIZE_EXPAND_FILL
	_button(bottom, "Settings", "settings", "settings", "NavButton")
	_button(bottom, "Field Guide", "guide", "guide", "NavButton")


func _home_mode(parent: Control, title: String, detail: String, route: String, icon: String, media: String) -> void:
	var card := _card(parent, "FieldPanel", 7)
	card.get_parent().size_flags_vertical = SIZE_EXPAND_FILL
	var line := _row(card, 12)
	line.size_flags_vertical = SIZE_EXPAND_FILL
	_photo(line, media, Vector2(96, 48), true)
	var copy := _column(line, 4)
	copy.size_flags_horizontal = SIZE_EXPAND_FILL
	_label(copy, title, "FieldStrong", 24)
	_label(copy, detail, "FieldMeta", 15)
	_button(card, "Open " + title, route, icon, "NavButton")


func _name() -> void:
	_backdrop(_surface, FIELD)
	var center := CenterContainer.new()
	_safe(_surface, EDGE).add_child(center)
	var card := _card(center, "LightPanel", 13)
	card.get_parent().custom_minimum_size = Vector2(490, 0)
	_photo(card, UI + "brand/hornbill.svg", Vector2(0, 118), false)
	_label(card, "Name your Leader", "PaperTitle")
	var line := LineEdit.new()
	line.placeholder_text = "Leader name"
	line.custom_minimum_size.y = TOUCH
	line.max_length = 24
	card.add_child(line)
	_button(card, "Continue", "home", "forward", "PrimaryButton")


func _story() -> void:
	var header := _row(_body, 12)
	_chip(header, "Control Room Lv.1", UI + "icons/light/control.svg")
	_gap(header)
	_button(header, "Headquarters", "headquarters", "headquarters", "NavButton")
	var art := _card(_body, "LightPanel", 10)
	art.get_parent().size_flags_vertical = SIZE_EXPAND_FILL
	_label(art, "Campaign operations", "PaperTitle")
	for chapter: int in [1, 2]:
		_label(art, "Chapter %d" % chapter, "PaperStrong")
		var timeline := GridContainer.new()
		timeline.columns = 5
		timeline.add_theme_constant_override("h_separation", 8)
		timeline.add_theme_constant_override("v_separation", 8)
		art.add_child(timeline)
		for number: int in range(1, 6 if chapter == 1 else 11):
			var available := chapter == 1 and number == 1
			var revealed := chapter == 1 and number <= 3
			var code := "C%d-%02d" % [chapter, number]
			var symbol := "campaign" if available else ("lock" if revealed else "fog")
			var node := _button(timeline, code, "plan" if available else "", symbol,
				"PrimaryButton" if available else "Button", available)
			node.size_flags_horizontal = SIZE_EXPAND_FILL
			node.tooltip_text = "First Contact" if available else ("Clear prerequisite" if revealed else "Control Room reveal required")
	var caption := _label(art, "Clear First Contact to unlock the next operation.", "PaperMeta")
	caption.set_meta("source_stage", "C1-01")


func _plan() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var left := _scroll(row)
	left.get_parent().size_flags_stretch_ratio = 1.08
	var stage := _card(left, "LightPanel", 7)
	_label(stage, "First Contact", "PaperTitle")
	_label(stage, "C1-01 · Forgotten Patrol", "PaperMeta")
	_photo(stage, FIELD, Vector2(0, 132), true)
	var startup := _card(left, "FieldPanel", 7)
	_label(startup, "Opening deployment", "FieldStrong")
	_label(startup, "Starter Logistics Post · 0 Logistic Tokens", "FieldMeta")
	_button(startup, "Edit modifiers", "modifiers", "settings", "NavButton")
	var right := _scroll(row)
	var loadout := _card(right, "LightPanel", 9)
	_label(loadout, "Loadout", "PaperStrong")
	_plan_actor(loadout, "Scout Sniper", "Elevated Ranger", "ranger_scout_sniper")
	_plan_actor(loadout, "Patrolman", "Ground Ranger", "ranger_patrolman")
	_plan_actor(loadout, "Logistics Post", "Mission supply", "facility_logistics_post")
	_button(loadout, "Edit Rangers", "loadout", "ranger")
	_button(loadout, "Edit Facilities", "facility_loadout", "facility")
	var intel := _card(right, "FieldPanel", 6)
	_label(intel, "Enemy intel", "FieldStrong")
	_label(intel, "Forest Trespasser · Danger 1", "FieldMeta")
	_action("Start operation", "pause", "play")


func _plan_actor(parent: Control, title: String, detail: String, basename: String) -> void:
	var line := _row(parent, 10)
	_photo(line, C28_BADGES + basename + ".png", Vector2(64, 64), false)
	var entries := _column(line, 2)
	entries.size_flags_horizontal = SIZE_EXPAND_FILL
	_label(entries, title, "PaperStrong", 20)
	_label(entries, detail, "PaperMeta", 16)


func _loadout(facility: bool) -> void:
	_tabs(_body, [["Rangers", "loadout", "ranger"], ["Facilities", "facility_loadout", "facility"]],
		"facility_loadout" if facility else "loadout")
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var available := _scroll(row)
	var card := _card(available, "LightPanel", 10)
	_label(card, "Mission supply" if facility else "Available Rangers", "PaperStrong")
	if facility:
		_plan_actor(card, "Logistics Post", "Starter Post · C1-01", "facility_logistics_post")
		_label(card, "Ordinary slots open by building Mechanical.", "PaperMeta")
		_button(card, "Mechanical", "room", "mechanical", "Button")
	else:
		_plan_actor(card, "Scout Sniper", "Selected · Elevated", "ranger_scout_sniper")
		_plan_actor(card, "Patrolman", "Selected · Ground", "ranger_patrolman")
		_label(card, "Select up to three Rangers", "PaperMeta")
		_meter(card, 2, 3)
	var details := _card(row, "FieldPanel")
	_label(details, "Supply allowance" if facility else "Ranger slots · 2/3", "FieldStrong")
	_label(details, "The mission Post does not use an ordinary Facility slot." if facility
		else "Human Resources increases Ranger capacity.", "FieldMeta")
	_action("Confirm selection", "plan", "check")


func _modifiers() -> void:
	var row := _row(_body)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var buffs := _card(row, "LightPanel")
	_label(buffs, "R&D support", "PaperStrong")
	_label(buffs, "Select one eligible effect.", "PaperMeta")
	_button(buffs, "No effect", "", "check")
	_button(buffs, "Research catalogue", "research", "research")
	var stage_effects := _card(row, "FieldPanel")
	_label(stage_effects, "Fixed stage effect", "FieldStrong")
	_label(stage_effects, "First Contact · D01", "FieldMeta")
	_label(stage_effects, "Applies for the duration of the operation.", "FieldMeta")
	_action("Confirm modifiers", "plan", "check")


func _modal(id: String) -> void:
	_backdrop(_surface, FIELD if id != "reset" else "")
	var center := CenterContainer.new()
	var body := _scroll(_safe(_surface, EDGE), 0)
	center.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(center)
	var light := id != "pause"
	var card := _card(center, "LightPanel" if light else "FieldPanel", 13)
	card.get_parent().custom_minimum_size.x = 588
	_label(card, PAGE_NAMES[id], "PaperTitle" if light else "FieldTitle")
	if id == "pause":
		_label(card, "C1-01 · First Contact", "FieldStrong")
		var marks := _row(card, 10)
		_chip(marks, "Wave 1/2", C28_INTERFACE + "wave.png")
		_chip(marks, "100 Integrity", C28_INTERFACE + "integrity.png")
		var intel := _card(card, "LightPanel", 8)
		_label(intel, "Enemy intel", "PaperStrong")
		_plan_actor(intel, "Forest Trespasser", "Danger 1 · 100 HP", "E01")
		var options := _row(card, 10)
		_button(options, "Controls", "guide", "guide", "NavButton").size_flags_horizontal = SIZE_EXPAND_FILL
		_button(options, "Settings", "settings", "settings", "NavButton").size_flags_horizontal = SIZE_EXPAND_FILL
		var actions := _row(card, 10)
		_button(actions, "Abandon operation", "abandon", "warning", "DangerButton")
		_button(actions, "Resume", "result", "play", "PrimaryButton").size_flags_horizontal = SIZE_EXPAND_FILL
		return
	_label(card, "Return to the operation plan without earning Funds." if id == "abandon"
		else "Remove your local progress and Leader name.", "PaperText")
	var actions := _row(card, 10)
	var cancel := _button(actions, "Keep playing" if id == "abandon" else "Cancel", "", "back")
	cancel.pressed.connect(go_back)
	cancel.size_flags_horizontal = SIZE_EXPAND_FILL
	_button(actions, "Abandon" if id == "abandon" else "Reset progress", "plan" if id == "abandon" else "naming",
		"warning", "DangerButton").size_flags_horizontal = SIZE_EXPAND_FILL


func _result(chaos: bool) -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var left := _card(row, "LightPanel", 8)
	left.get_parent().size_flags_stretch_ratio = 1.1
	var seal := _photo(left, C28_INTERFACE + "result_perfect.png", Vector2(0, 105), false)
	seal.size_flags_vertical = SIZE_EXPAND_FILL
	_label(left, "Victorious run" if chaos else "Perfect clear", "PaperTitle")
	_label(left, "Forgotten Patrol · Rainforest Chaos" if chaos else "C1-01 · First Contact", "PaperMeta")
	_gap(left, true)
	var right := _card(row, "FieldPanel", 10)
	_label(right, "Settlement", "FieldStrong")
	if chaos:
		_result_row(right, "Medal Score", "1,350")
		_result_row(right, "Defeated", "60/60")
		_result_row(right, "Funds earned", "54,000")
	else:
		_result_row(right, "Operational Integrity", "100")
		_result_row(right, "Defeated", "14/14")
		_result_row(right, "Escapes", "0")
		_result_row(right, "First clear", "10,000 Funds")
	_action("Return to routes" if chaos else "Return to Story", "chaos_routes" if chaos else "story", "map")


func _result_row(parent: Control, label: String, amount: String) -> void:
	var row := _row(parent, 12)
	_label(row, label, "FieldMeta").size_flags_horizontal = SIZE_EXPAND_FILL
	_label(row, amount, "FieldStrong", 19)


func _settings() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var audio := _card(row, "LightPanel", 12)
	_label(audio, "Audio", "PaperStrong")
	for label: String in ["Master volume", "Music", "Effects"]:
		_label(audio, label, "PaperMeta")
		var slider := HSlider.new()
		slider.custom_minimum_size.y = TOUCH
		slider.value = 80.0
		audio.add_child(slider)
	var settings := _card(row, "FieldPanel", 9)
	_label(settings, "Text size", "FieldStrong")
	var ratios := _row(settings, 8)
	var options := ButtonGroup.new()
	for percentage in [100, 115, 130]:
		var size_button := _button(ratios, str(percentage) + "%", "", "", "NavButton")
		size_button.size_flags_horizontal = SIZE_EXPAND_FILL
		size_button.toggle_mode = true
		size_button.button_group = options
		size_button.set_pressed_no_signal(percentage == roundi(zoom * 100.0))
		size_button.pressed.connect(_set_zoom.bind(float(percentage) / 100.0))
	_gap(settings, true)
	_label(settings, "Local progress", "FieldStrong")
	_label(settings, "Your profile is stored on this device.", "FieldMeta")
	_button(settings, "Reset local progress", "reset", "warning", "DangerButton")


func _set_zoom(value: float) -> void:
	zoom = value
	show_page(active_page)


func _hq_art() -> String:
	return _media([HUB_FALLBACK + "w29/overview.png", HUB_FALLBACK + "overview.png",
		HUB_FALLBACK + "shell.png", HUB_FALLBACK + "shell/overview.png"], FIELD)


func _headquarters() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var picture := _card(row, "LightPanel", 9)
	picture.get_parent().size_flags_stretch_ratio = 0.83
	var visual := _photo(picture, _hq_art(), Vector2(0, 170), true)
	visual.size_flags_vertical = SIZE_EXPAND_FILL
	_label(picture, "Headquarters", "PaperTitle")
	_label(picture, "Select a department to manage it.", "PaperMeta")
	_button(picture, "Ranger catalogue", "roster", "ranger", "PrimaryButton")
	var rooms := _scroll(row)
	rooms.get_parent().size_flags_stretch_ratio = 1.17
	var grid := GridContainer.new()
	grid.columns = 2
	rooms.add_child(grid)
	for index in ROOMS.rooms.size():
		var room: HeadquartersRoom = ROOMS.rooms[index]
		var room_card := _card(grid, "FieldPanel", 4)
		_label(room_card, room.label, "FieldStrong", 19)
		var state := "Level 1" if index < 3 else "Unbuilt"
		_label(room_card, state, "FieldMeta", 15)
		var access := _button(room_card, "Open", "", ROOM_ICONS[index], "NavButton")
		access.pressed.connect(_open_room.bind(room.id))


func _open_room(id: StringName) -> void:
	selected_room_id = id
	open_page("room")


func _room() -> void:
	var label := _visible_title("room")
	var row := _row(_body, 15)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var left := _card(row, "LightPanel")
	var slug := String(selected_room_id).get_slice(".", 1)
	var art := _media([HUB_FALLBACK + "w29/rooms/" + slug + "/interior.png",
		HUB_FALLBACK + "rooms/" + slug + "/interior.png"], _hq_art())
	_photo(left, art, Vector2(0, 140), true).size_flags_vertical = SIZE_EXPAND_FILL
	_label(left, label, "PaperTitle")
	var status := "Unbuilt" if slug == "mechanical" else "Level 1 of 5"
	_label(left, status, "PaperText")
	var detail := _card(row, "FieldPanel", 11)
	_label(detail, "Room details", "FieldStrong")
	match slug:
		"control_room":
			_label(detail, "Revealed operations: C1-01–03", "FieldMeta")
			_button(detail, "Story Mode", "story", "campaign", "PrimaryButton")
		"human_resources":
			_label(detail, "Capacity: 3 Ranger slots", "FieldMeta")
			_button(detail, "Ranger catalogue", "roster", "ranger", "PrimaryButton")
		"finance_room":
			_label(detail, "Active income: 2 Funds/s · Capacity 12,000", "FieldMeta")
			_button(detail, "Claim stored Funds", "", "check", "Button", false)
		"mechanical":
			_label(detail, "Building Mechanical opens two Facility slots.", "FieldMeta")
			_label(detail, "Build cost · 20,000 Funds", "FieldStrong")
			_button(detail, "Facility catalogue", "facility_loadout", "facility", "PrimaryButton")
		"ecology":
			_label(detail, "Plot capacity begins at two.", "FieldMeta")
			_button(detail, "Habitat Restoration", "garden", "restoration", "PrimaryButton")
		"outreach":
			_button(detail, "Outreach questions", "outreach", "outreach", "PrimaryButton")
		"records":
			_button(detail, "Browse Records", "records", "records", "PrimaryButton")
		_:
			_button(detail, "Research catalogue", "research", "research", "PrimaryButton")
	_action("Headquarters", "headquarters", "headquarters", "NavButton")


func _research() -> void:
	var list := _scroll(_body)
	var first := _card(list, "LightPanel", 10)
	_label(first, "Research catalogue", "PaperStrong")
	_label(first, "Each room unlocks distinct effects as its level increases.", "PaperMeta")
	var grid := GridContainer.new()
	grid.columns = 2
	list.add_child(grid)
	var names := ["R&D Eco", "R&D Combat", "R&D Guard", "R&D Crisis"]
	for index in names.size():
		var card := _card(grid, "FieldPanel")
		_label(card, names[index], "FieldStrong")
		_label(card, ["B01–B04", "B05–B08", "B09–B12", "B13–B15"][index], "FieldMeta")
		_button(card, "View room", "room", ROOM_ICONS[index + 7], "NavButton")
	_action("Operation modifiers", "modifiers", "settings", "NavButton")


func _roster() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var card := _card(row, "LightPanel")
	_label(card, "Owned Rangers", "PaperStrong")
	_plan_actor(card, "Scout Sniper", "Offense · Lv.1", "ranger_scout_sniper")
	_plan_actor(card, "Patrolman", "Guard · Lv.1", "ranger_patrolman")
	_button(card, "View Scout Sniper", "unit", "ranger", "PrimaryButton")
	var access := _card(row, "FieldPanel")
	_label(access, "Catalogue", "FieldStrong")
	_label(access, "Human Resources · 3 Ranger slots", "FieldMeta")
	_button(access, "Facilities", "facility_loadout", "facility", "NavButton")


func _unit() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var card := _card(row, "LightPanel")
	_photo(card, C28_BADGES + "ranger_scout_sniper.png", Vector2(0, 144), false).size_flags_vertical = SIZE_EXPAND_FILL
	_label(card, "Scout Sniper", "PaperTitle")
	_label(card, "Level 1 · Offense · Elevated", "PaperMeta")
	var quotes := _card(row, "FieldPanel")
	_label(quotes, "Level upgrade", "FieldStrong")
	_result_row(quotes, "Target", "Lv.20")
	_result_row(quotes, "Quote", "60,096 Funds")
	_label(quotes, "Shortfall · 40,096 Funds", "FieldMeta")
	_button(quotes, "Upgrade", "", "lock", "Button", false)


func _chaos_routes() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var list := _scroll(row)
	for index: int in REGIONS.size():
		var option := _button(list, REGIONS[index], "", "map", "NavButton")
		option.pressed.connect(_view_chaos_region.bind(index))
	var map := _card(row, "LightPanel", 9)
	map.get_parent().size_flags_stretch_ratio = 1.35
	var id := "T%02d" % (selected_chaos_region + 1)
	var art := FIELD if selected_chaos_region == 0 else "res://assets/imported/environments/%s/card_wide.jpg" % id.to_lower()
	_photo(map, art, Vector2(0, 140), true).size_flags_vertical = SIZE_EXPAND_FILL
	_label(map, REGIONS[selected_chaos_region], "PaperTitle").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(map, "%d entrance%s · %s" % [2 if selected_chaos_region == 1 else 1,
		"s" if selected_chaos_region == 1 else "", id], "PaperMeta")
	var score := _card(row, "FieldPanel", 9)
	_label(score, "Trophy record", "FieldStrong")
	_label(score, "Personal best", "FieldMeta")
	_label(score, "1,350", "FieldTitle")
	_meter(score, 1350, 3000)
	_label(score, "Tiers · 1,000 / 2,000 / 3,000", "FieldMeta").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action("Configure run", "chaos_composer", "settings")


func _view_chaos_region(index: int) -> void:
	selected_chaos_region = index
	show_page("chaos_routes")


func _chaos_composer() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var waves := _scroll(row)
	var config := _card(waves, "LightPanel")
	_label(config, "Waves", "PaperStrong")
	_label(config, "2 populated · 3 empty", "PaperMeta")
	for wave: String in ["Wave 1 · 50/50 enemies", "Wave 2 · 10/50 enemies", "Wave 3 · Empty", "Wave 4 · Empty", "Wave 5 · Empty"]:
		_button(config, wave, "", "list")
	var side := _card(row, "FieldPanel")
	_label(side, "Medal Score", "FieldStrong")
	_label(side, "1,350", "FieldTitle")
	_result_row(side, "Enemies", "1,550")
	_result_row(side, "Challenge effects", "+400")
	_result_row(side, "Loadout", "−500")
	_result_row(side, "Support effects", "−100")
	_button(side, "Edit modifiers", "modifiers", "settings", "NavButton")
	_action("Start run", "chaos_result", "play")


func _garden() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var field := _card(row, "LightPanel", 8)
	field.get_parent().size_flags_stretch_ratio = 1.32
	_photo(field, GARDEN + "garden_clearing.jpg", Vector2(0, 135), true).size_flags_vertical = SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = 3
	field.add_child(grid)
	for slot in 6:
		var enabled := slot < 2
		var plot := _button(grid, "Plot %d" % (slot + 1), "seeds" if enabled else "", "restoration" if enabled else "lock",
			"Button", enabled)
		plot.size_flags_horizontal = SIZE_EXPAND_FILL
	var status := _card(row, "FieldPanel")
	_label(status, "0% restored", "FieldStrong")
	_meter(status, 0, 100)
	_label(status, "2 plots available", "FieldMeta")
	_label(status, "Build up plot capacity at Ecology.", "FieldMeta")
	_button(status, "Ecology", "", "ecology", "NavButton").pressed.connect(_open_room.bind(&"room.ecology"))
	_button(status, "Garden guide", "guide", "guide", "NavButton")


func _seeds() -> void:
	var garden := _scroll(_body)
	var grid := GridContainer.new()
	grid.columns = 2
	garden.add_child(grid)
	for species: Array in SPECIES:
		var card := _card(grid, "LightPanel")
		var art := GARDEN + "trees/" + String(species[0]) + "/mature.png"
		_photo(card, art, Vector2(0, 95), false)
		_label(card, species[1], "PaperStrong")
		_label(card, "Growth time · " + species[2], "PaperMeta")
		_button(card, "Choose seed", "garden", "restoration", "PrimaryButton")


func _outreach() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var manager := _card(row, "FieldPanel")
	manager.get_parent().size_flags_stretch_ratio = 0.72
	_photo(manager, C28 + "manager_briefing.png", Vector2(0, 155), false).size_flags_vertical = SIZE_EXPAND_FILL
	_label(manager, "Operations Manager", "FieldStrong")
	var detail := _card(row, "LightPanel")
	_label(detail, "Current batch", "PaperTitle")
	_label(detail, "Up to 5 questions every 20 hours from a rotating bank of 20.", "PaperText")
	_label(detail, "Question set unavailable", "PaperMeta")
	_button(detail, "Open batch", "", "lock", "Button", false)
	_action("Return to Headquarters", "headquarters", "headquarters", "NavButton")


func _records() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var archive := _card(row, "LightPanel")
	_label(archive, "Encyclopaedia", "PaperTitle")
	_photo(archive, GARDEN + "hornbill_guide.png", Vector2(0, 100), false).size_flags_vertical = SIZE_EXPAND_FILL
	_button(archive, "Browse references", "guide", "guide", "PrimaryButton")
	var chapters := _card(row, "FieldPanel")
	_label(chapters, "Quiz chapters", "FieldStrong")
	for chapter in ["Field Identification", "Habitat Dynamics", "Conservation Practice", "Field Operations"]:
		_button(chapters, chapter, "quiz" if chapter == "Field Identification" else "",
			"quiz" if chapter == "Field Identification" else "lock", "NavButton", chapter == "Field Identification")


func _quiz() -> void:
	var question := _card(_body, "LightPanel", 11)
	var row := _row(question)
	_chip(row, "Question 1/5", "", true)
	_gap(row)
	_chip(row, "15 s", UI + "icons/dark/clock.svg", true)
	_label(question, "What can a hornbill spread across the forest?", "PaperStrong")
	for answer in ["Seeds", "Salt", "Sand", "Water"]:
		_button(question, answer, "", "")
	_label(question, "Answer state appears below the choices.", "PaperMeta")
	_action("Return to Records", "records", "records", "NavButton")


func _guide() -> void:
	var row := _row(_body, 14)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	var sections := _card(row, "FieldPanel")
	sections.get_parent().size_flags_stretch_ratio = 0.63
	_label(sections, "Reference", "FieldStrong")
	for item in ["Landscape controls", "Placement and facing", "Story visibility", "Conservation references"]:
		_button(sections, item, "", "guide", "NavButton")
	var paper := _card(row, "LightPanel", 9)
	_label(paper, "Landscape controls", "PaperTitle")
	_label(paper, "Swipe the deployment tray to see the selected Rangers and Facilities.", "PaperText")
	_label(paper, "Drag a card to a compatible tile. Hold a deployed Ranger to view retreat options.", "PaperText")
	_label(paper, "Pause to inspect threats, open Settings or return to the operation plan.", "PaperMeta")
