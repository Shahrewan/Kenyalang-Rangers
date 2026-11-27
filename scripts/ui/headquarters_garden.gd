class_name HeadquartersGarden
extends VBoxContainer

signal article_requested(id: String)
signal back_requested
signal sound_requested(id: String)
signal ecology_requested

enum View { PLOT, SEEDS, GUIDE, MILESTONES, COLLECTION }

var progress: CampaignProgress
var catalog: EducationCatalog
var read_time: Callable = Time.get_unix_time_from_system
var _capacity: int
var _state: Dictionary
var _stages: Array[int] = []
var _last_time: int
var _quiet_growth_refresh := false
var _slot := 0
var _view := View.PLOT
var _receipt: Dictionary
var _collected_species: String
var _board: GardenBoard
var _scroll: ScrollContainer
var _details: VBoxContainer
var _status: Label
var _funds: Label
var _meter: ProgressBar
var _timer: Label
var _notice: Label
var _primary: HBoxContainer
var _side: PanelContainer
var _nav: HBoxContainer

func _ready() -> void:
	set_process(false)
	add_theme_constant_override("separation", 12)
	StoryUI.header(self, "Habitat Restoration", func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	_capacity = progress.room_capacity(HeadquartersCatalog.ECOLOGY)
	if _capacity == 0:
		var locked := StoryUI.panel(StoryUI.scroll_column(self))
		locked.add_child(StoryUI.label("Build Ecology to open the first two plots.", 25))
		_add_button(locked, "Open Ecology", "OpenEcology", func() -> void: ecology_requested.emit(), true)
		return
	_funds = find_child("FundsSummary", true, false)
	var layout := StoryUI.row(self, 16)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board = GardenBoard.new()
	_board.name = "GardenBoard"
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.size_flags_stretch_ratio = 1.4
	_board.plot_selected.connect(_select_plot)
	layout.add_child(_board)

	_side = PanelContainer.new()
	_side.custom_minimum_size.x = 390
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_side)
	var info := StoryUI.column(_side, 10)
	_status = StoryUI.label("", 22, StoryUI.AMBER)
	info.add_child(_status)
	_meter = ProgressBar.new()
	_meter.show_percentage = false
	_meter.custom_minimum_size.y = 14
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(_meter)
	_nav = StoryUI.row(info, 6)
	_add_button(_nav, "Guide", "GardenGuide", _open_guide)
	_add_button(_nav, "Milestones", "GardenMilestones", _show_view.bind(View.MILESTONES))
	_add_button(_nav, "Ecology", "GardenEcology", func() -> void: ecology_requested.emit())
	_details = StoryUI.scroll_column(info)
	_scroll = _details.get_parent()
	_scroll.scroll_deadzone = 12
	_primary = StoryUI.row(info)
	_notice = StoryUI.label("", 19, StoryUI.AMBER)
	_notice.hide()
	add_child(_notice)

	_save_clock()
	_refresh()
	set_process(true)

func _process(_delta: float) -> void:
	var now := _now()
	if now == _last_time:
		return
	_last_time = now
	var stages := _growth_stages()
	if stages != _stages:
		var selected_changed := _slot < _capacity and stages[_slot] != _stages[_slot]
		if not _quiet_growth_refresh and selected_changed and _view == View.PLOT and stages[_slot] in [RestorationRules.Stage.SAPLING, RestorationRules.Stage.MATURE]:
			sound_requested.emit("restoration_growth_ready")
		_save_clock()
		_refresh(selected_changed and _view == View.PLOT)
	elif is_instance_valid(_timer):
		_timer.text = _time_caption(_plot())
	_quiet_growth_refresh = false

func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT) and is_node_ready() and _capacity > 0:
		_quiet_growth_refresh = true
		_save_clock()

func _exit_tree() -> void:
	if _capacity > 0:
		progress.checkpoint_garden(_now())

func _now() -> int:
	return int(read_time.call())

func _save_clock() -> void:
	if progress.checkpoint_garden(_now()):
		_state = progress.garden_state()
	else:
		_show_error("Could not save garden progress. Check local storage.")

func _refresh(render := true) -> void:
	_last_time = _now()
	_state = progress.garden_state()
	_stages = _growth_stages()
	var percent := progress.restoration_percent()
	_status.text = "%d%% restored · %d available plots" % [percent, _capacity]
	_meter.value = percent
	_funds.text = "%s Funds" % StoryUI.funds(progress.funds())
	_board.present(_state, _last_time, _capacity, _slot)
	if render:
		_render_details()
	elif is_instance_valid(_timer):
		_timer.text = _time_caption(_plot())

func _growth_stages() -> Array[int]:
	var stages: Array[int] = []
	for slot in _capacity:
		stages.append(RestorationRules.stage(_state.plots.get(RestorationRules.plot_id(slot), {}), _last_time))
	return stages

func _select_plot(slot: int) -> void:
	_slot = slot
	_board.present(_state, _last_time, _capacity, _slot)
	_show_view(View.PLOT)

func _show_view(view: View) -> void:
	_view = view
	_notice.hide()
	_render_details()

func _render_details() -> void:
	_timer = null
	EducationUI.clear(_details)
	EducationUI.clear(_primary)
	_scroll.scroll_vertical = 0
	var picking_seed := _view == View.SEEDS
	_nav.visible = not picking_seed
	_board.set_plot_controls_visible(not picking_seed)
	_board.size_flags_stretch_ratio = 0.88 if picking_seed else 1.4
	_side.size_flags_stretch_ratio = 1.42 if picking_seed else 0.92
	match _view:
		View.PLOT: _render_plot()
		View.SEEDS: _render_seeds()
		View.GUIDE: _render_guide()
		View.MILESTONES: _render_milestones()
		View.COLLECTION: _render_collection()
	_primary.visible = _primary.get_child_count() > 0
	StoryUI.size_buttons(self)

func _render_plot() -> void:
	_details.add_child(StoryUI.label("Plot %d" % (_slot + 1), 27, StoryUI.AMBER))
	if _slot >= _capacity:
		_details.add_child(StoryUI.label("Requires Ecology Lv.%d" % maxi(1, _slot), 22))
		_details.add_child(StoryUI.label("Upgrade Ecology to open this plot.", 19, StoryUI.BEIGE))
		return
	var plot := _plot()
	if plot.is_empty():
		var id := RestorationRules.plot_id(_slot)
		if _state.scenery.has(id):
			var retained: Dictionary = RestorationRules.SPECIES[_state.scenery[id]]
			_details.add_child(StoryUI.label("%s is part of the garden. This plot is ready to replant." % retained.label, 20))
		else:
			_details.add_child(StoryUI.label("This plot is ready for a seed.", 21))
		_add_button(_primary, "Choose a seed", "ChooseSeed", _show_view.bind(View.SEEDS), true)
		return
	var species: Dictionary = RestorationRules.SPECIES[plot.species]
	var stage := RestorationRules.stage(plot, _last_time)
	_details.add_child(StoryUI.label(species.label, 22))
	_details.add_child(StoryUI.label("Mature" if stage == RestorationRules.Stage.MATURE else ("Sapling" if stage == RestorationRules.Stage.SAPLING else "Seed"), 20, StoryUI.BEIGE))
	if RestorationRules.needs_water(plot, _last_time):
		_details.add_child(StoryUI.label("Growth paused at halfway. Water to resume.", 20))
		_add_button(_primary, "Water", "WaterPlot", _water.bind(_slot, plot.cycle_id), true)
	elif stage == RestorationRules.Stage.MATURE:
		_details.add_child(StoryUI.label("Collect %s Funds for this cycle." % StoryUI.funds(species.funds), 20))
		_add_button(_primary, "Collect", "CollectPlot", _collect.bind(_slot, plot.cycle_id), true)
	else:
		_timer = StoryUI.label(_time_caption(plot), 20, StoryUI.AMBER)
		_details.add_child(_timer)

func _render_seeds() -> void:
	_details.add_child(StoryUI.label("Choose a seed for Plot %d" % (_slot + 1), 24, StoryUI.AMBER))
	_details.add_child(StoryUI.label("Planting is free. These are in-game growth times.", 18, StoryUI.BEIGE))
	var rows := StoryUI.column(_details, 8)
	var row: HBoxContainer
	var index := 0
	for id: String in RestorationRules.SPECIES:
		if index % 2 == 0:
			row = StoryUI.row(rows, 8)
		index += 1
		var species: Dictionary = RestorationRules.SPECIES[id]
		var label := "%s\n%dh · %s Funds" % [species.label, species.hours, StoryUI.funds(species.funds)]
		var button := _add_button(row, label, "Plant_" + id.get_slice(".", 1), _plant.bind(_slot, id))
		button.icon = _board._texture("trees/%s/seed.png" % id.get_slice(".", 1))
		button.add_theme_constant_override("icon_max_width", 44)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 116
	_add_button(_primary, "Cancel seed selection", "CancelSeed", _show_view.bind(View.PLOT))

func _render_guide() -> void:
	_details.add_child(StoryUI.label("Rhinoceros Hornbill guide", 25, StoryUI.AMBER))
	_details.add_child(StoryUI.label("Water once at the halfway point. The plant will wait for you. Growth can continue while the app is closed.", 19))
	var facts := PackedStringArray([RestorationRules.GUIDE_FACT])
	for id: String in _state.collected_species:
		facts.append(RestorationRules.SPECIES[id].fact)
	if _state.nest_box_seen:
		facts.append(RestorationRules.NEST_FACT)
	_show_facts(facts)
	_add_button(_primary, "Back to plot", "GardenCloseGuide", _show_view.bind(View.PLOT))

func _render_milestones() -> void:
	_details.add_child(StoryUI.label("Restoration milestones", 25, StoryUI.AMBER))
	_details.add_child(StoryUI.label("Collect all four species once, then collect one more mature tree. Ecology Lv.5 requires 60% restoration and the room price.", 19))
	for percent: int in RestorationRules.MILESTONES:
		var reached: bool = "restoration_milestone.%d" % percent in _state.milestones
		var marker := "Collected" if reached else "Upcoming"
		if not reached and percent <= progress.restoration_percent():
			marker = "Reached"
		_details.add_child(StoryUI.label("%d%% · %s Funds · %s" % [percent, StoryUI.funds(RestorationRules.MILESTONES[percent]), marker], 19, StoryUI.BEIGE))
	_add_button(_primary, "Back to plot", "GardenCloseMilestones", _show_view.bind(View.PLOT))

func _render_collection() -> void:
	_details.add_child(StoryUI.label("%s collected" % RestorationRules.SPECIES[_collected_species].label, 25, StoryUI.AMBER))
	_details.add_child(StoryUI.label(EducationUI.receipt(_receipt.credited, _receipt.discarded), 21))
	if _receipt.milestone_funds > 0:
		_details.add_child(StoryUI.label("%d%% milestone · %s Funds" % [_receipt.milestone, StoryUI.funds(_receipt.milestone_funds)], 19))
	var facts := PackedStringArray()
	if _receipt.visitor:
		_details.add_child(StoryUI.label("Nest box installed · A hornbill visited", 22, StoryUI.AMBER))
		facts.append(RestorationRules.NEST_FACT)
	if not String(_receipt.fact).is_empty():
		facts.append(_receipt.fact)
	_show_facts(facts)
	_add_button(_primary, "Replant", "ChooseSeed", _show_view.bind(View.SEEDS), true)

func _show_facts(ids: PackedStringArray) -> void:
	var pending := false
	for id in ids:
		var fact: Dictionary = catalog.facts.get(id, {})
		if fact.is_empty():
			pending = true
			continue
		_details.add_child(StoryUI.label(fact.title, 21, StoryUI.AMBER))
		_details.add_child(StoryUI.label(fact.text, 19))
		EducationUI.credit_sources(_details, catalog, fact.source_ids, StoryUI.BEIGE)
		_add_button(_details, "Read article", "Article_" + id.get_slice(".", 1), func() -> void: article_requested.emit(id))
	if pending:
		_details.add_child(StoryUI.label("Field note awaiting approval.", 17, StoryUI.BEIGE))

func _open_guide() -> void:
	if progress.visit_garden_guide():
		_show_view(View.GUIDE)
	else:
		_show_error("Could not save the guide discovery. Check local storage.")

func _plant(slot: int, species: String) -> void:
	if progress.plant_garden(slot, species, _now()).is_empty():
		_show_error("Could not plant here. Use an open plot and check local storage.")
		return
	_view = View.PLOT
	_notice.hide()
	_refresh()
	sound_requested.emit("restoration_plant")

func _water(slot: int, cycle: String) -> void:
	if not progress.water_garden(slot, cycle, _now()):
		_show_error("Could not water here. Check that the plot needs water and local storage is available.")
		return
	_notice.hide()
	_refresh()
	sound_requested.emit("water")
	_board.play_effect("water", slot)

func _collect(slot: int, cycle: String) -> void:
	var settlement := progress.collect_garden(slot, cycle, _now())
	if settlement.is_empty():
		_show_error("Could not collect. Check that the tree is mature and local storage is available.")
		return
	_collected_species = settlement.species
	_slot = slot
	_receipt = settlement
	_view = View.COLLECTION
	_notice.hide()
	_refresh()
	var cue := "restoration_visitor" if settlement.visitor else "restoration_collect"
	if not settlement.visitor and settlement.milestone_funds > 0:
		cue = "restoration_milestone"
	sound_requested.emit(cue)
	_board.play_effect("collect", slot, settlement.visitor)

func _plot() -> Dictionary:
	return _state.plots.get(RestorationRules.plot_id(_slot), {})

func _show_error(message: String) -> void:
	_notice.text = message
	_notice.show()

func _time_caption(plot: Dictionary) -> String:
	var minutes := ceili(RestorationRules.remaining(plot, _last_time) / 60.0)
	var duration := "%dh %02dm" % [floori(minutes / 60.0), minutes % 60] if minutes >= 60 else "%dm" % minutes
	return ("Ready to water in %s" if plot.watered_at == 0 else "Ready to collect in %s") % duration

static func _add_button(parent: Container, caption: String, node_name: String, callback: Callable, primary := false) -> Button:
	var button := EducationUI.large_action(StoryUI.action(caption, primary), 74.0 if primary else 64.0)
	button.name = node_name
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
