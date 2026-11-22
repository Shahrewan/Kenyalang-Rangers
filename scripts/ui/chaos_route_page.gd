class_name ChaosRoutePage
extends VBoxContainer

signal back_requested
signal configure_requested
signal trial_requested

var configuration: ChaosConfiguration
var progress: CampaignProgress
var _board: BattleBoard
var _route_info: Label
var _choice := ButtonGroup.new()
var _buttons: Dictionary[StringName, Button] = {}

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	StoryUI.header(self, "Rainforest Chaos", func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	var body := StoryUI.row(self, 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list := StoryUI.scroll_column(body)
	list.custom_minimum_size.x = 260
	for route_id: StringName in ChaosConfiguration.ROUTES:
		var route := StoryUI.action(ChaosConfiguration.ROUTES[route_id])
		route.name = "Route_" + String(route_id)
		route.toggle_mode = true
		route.button_group = _choice
		route.pressed.connect(_select_route.bind(route_id))
		_buttons[route_id] = route
		list.add_child(route)
	var map := StoryUI.panel(body)
	map.get_parent().size_flags_stretch_ratio = 1.7
	_route_info = StoryUI.label("", 20, StoryUI.AMBER)
	map.add_child(_route_info)
	_board = BattleBoard.new()
	_board.custom_minimum_size = Vector2(180, 175)
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(_board)
	map.add_child(StoryUI.label("Placeholder route art", 16, StoryUI.BEIGE))
	var record := StoryUI.panel(StoryUI.scroll_column(body))
	record.custom_minimum_size.x = 275
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
	_buttons[id].set_pressed_no_signal(true)
	var preview := configuration.build_stage()
	_board.battle_map = preview.map
	_board.routes = preview.routes
	var entries := "1 entry" if preview.routes.size() == 1 else "%d entries" % preview.routes.size()
	_route_info.text = entries + (" · Heat enabled" if preview.heat_capacity > 0.0 else "")
	_board.queue_redraw()
