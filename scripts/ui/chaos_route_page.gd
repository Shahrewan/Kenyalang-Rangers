class_name ChaosRoutePage
extends VBoxContainer

signal back_requested
signal configure_requested
signal trial_requested

var configuration: ChaosConfiguration
var progress: CampaignProgress
var _board: BattleBoard
var _route_info: Label
var _preview: AspectRatioContainer
var _choice := ButtonGroup.new()
var _buttons: Dictionary[StringName, Button] = {}
var _skin := FirstContactSkin.new()

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	StoryUI.header(self, "Rainforest Chaos", func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	var body := StoryUI.row(self, 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list := StoryUI.scroll_column(body)
	list.get_parent().custom_minimum_size.x = 268
	for route_id: StringName in ChaosConfiguration.ROUTES:
		var route := StoryUI.action(ChaosConfiguration.ROUTES[route_id])
		route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		route.name = "Route_" + String(route_id)
		route.toggle_mode = true
		route.button_group = _choice
		route.pressed.connect(_select_route.bind(route_id))
		_buttons[route_id] = route
		list.add_child(route)
	var map := StoryUI.panel(body)
	map.get_parent().size_flags_stretch_ratio = 2.15
	_route_info = StoryUI.label("", 20, StoryUI.AMBER)
	map.add_child(_route_info)
	_preview = AspectRatioContainer.new()
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.add_child(_preview)
	_board = BattleBoard.new()
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.add_child(_board)
	var records := StoryUI.scroll_column(body)
	records.get_parent().custom_minimum_size.x = 300
	var record := StoryUI.panel(records)
	var trophy := ChaosTrophy.new()
	trophy.personal_best = progress.chaos_personal_best()
	trophy.show_thresholds = true
	record.add_child(trophy)

	var actions := StoryUI.row(self)
	var trial := StoryUI.action("Modifier trial")
	trial.name = "OpenModifierTrial"
	trial.pressed.connect(func() -> void: trial_requested.emit())
	actions.add_child(trial)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(gap)
	var configure := StoryUI.action("Configure run", true)
	configure.name = "ConfigureChaos"
	configure.pressed.connect(func() -> void: configure_requested.emit())
	actions.add_child(configure)
	_select_route(configuration.route_id)

func _select_route(id: StringName) -> void:
	configuration.select_route(id)
	for key: StringName in _buttons:
		_buttons[key].set_pressed_no_signal(key == id)
	var preview := configuration.build_stage()
	_preview.ratio = float(preview.map.size.x) / preview.map.size.y
	_board.show_landscape(preview, _skin)
	var entries := "1 entry" if preview.routes.size() == 1 else "%d entries" % preview.routes.size()
	_route_info.text = entries + (" · Heat enabled" if preview.heat_capacity > 0.0 else "")
	if _board.first_contact_field == null:
		_route_info.text += " · Map illustration unavailable"
