class_name HeadquartersGarden
extends VBoxContainer

signal back_requested
signal ecology_requested

var progress: CampaignProgress

func _ready() -> void:
	StoryUI.header(self, "Habitat Restoration", func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	var main := StoryUI.scroll_column(self)
	var capacity := progress.room_capacity(HeadquartersCatalog.ECOLOGY)
	if capacity == 0:
		main.add_child(StoryUI.label("Build Ecology to open the first two plots.", 23))
		var ecology := StoryUI.action("Open Ecology", true)
		ecology.pressed.connect(func() -> void: ecology_requested.emit())
		main.add_child(ecology)
		return
	main.add_child(StoryUI.label("%d%% restoration · %d available plots" % [progress.restoration_percent(), capacity], 23))
	var plots := GridContainer.new()
	plots.columns = 3
	plots.add_theme_constant_override("h_separation", 8)
	plots.add_theme_constant_override("v_separation", 8)
	main.add_child(plots)
	var state: Dictionary = progress.snapshot().garden
	for i in 6:
		var view := StoryUI.panel(plots)
		var id := "garden_plot.%02d" % (i + 1)
		view.add_child(StoryUI.label("Plot %d" % (i + 1), 23, StoryUI.AMBER))
		if i >= capacity:
			view.add_child(StoryUI.label("Requires Ecology Lv.%d" % i, 18))
		elif state.plots.has(id):
			var plot: Dictionary = state.plots[id]
			view.add_child(StoryUI.label("%s · %s" % [String(plot.species).get_slice(".", 1).capitalize(), "Watering saved" if plot.watered_at > 0 else "Planting saved"], 18))
		else:
			view.add_child(StoryUI.label("Empty", 18))
	main.add_child(StoryUI.label("Planting and collection are pending the Restoration activity.", 17, StoryUI.BEIGE))
