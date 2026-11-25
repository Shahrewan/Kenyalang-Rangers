class_name HeadquartersRosterPage
extends VBoxContainer

signal back_requested
signal unit_requested(spec: DeploymentSpec)

var rangers := true
var progress: CampaignProgress
var _art := CampaignVisualAssets.new()

func _ready() -> void:
	theme = HeadquartersArt.THEME
	add_theme_constant_override("separation", 12)
	var title := "Ranger upgrades" if rangers else "Facility upgrades"
	var back := StoryUI.header(self, title, func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	back.custom_minimum_size.y = 64
	var body := StoryUI.scroll_column(self)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for spec in DeployableLevels.catalog(rangers):
		_add_unit(grid, spec)

func _add_unit(grid: GridContainer, spec: DeploymentSpec) -> void:
	var owned := progress.owns(spec.id)
	var level := "Level %d" % progress.deployable_level(spec.id) if owned else "Locked"
	var text := "%s\n%s" % [spec.label, level]
	if not owned:
		text += " · " + lock_message(spec)
	var open := StoryUI.action(text)
	open.name = "Unit_" + String(spec.id).get_slice(".", 1)
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.custom_minimum_size.y = 108
	open.alignment = HORIZONTAL_ALIGNMENT_LEFT
	open.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	open.icon = _art.badge(spec.id)
	open.expand_icon = true
	open.add_theme_constant_override("icon_max_width", 62)
	open.add_theme_constant_override("h_separation", 14)
	open.accessibility_description = "Review levels" if owned else "Review unlock requirements"
	open.pressed.connect(func() -> void: unit_requested.emit(spec))
	grid.add_child(open)

static func lock_message(spec: DeploymentSpec) -> String:
	if spec is FacilitySpec:
		if spec.chaos_threshold > 0:
			return "Qualifying Chaos score of %s" % StoryUI.funds(spec.chaos_threshold)
		if not spec.mission_supply_stage.is_empty():
			if not spec.recruitment_stage.is_empty():
				return "Clear %s to recruit. Supplied during %s." % [spec.recruitment_stage, spec.mission_supply_stage]
			return "Mission supply in %s. Permanent availability pending." % spec.mission_supply_stage
		if not spec.recruitment_stage.is_empty():
			return "Clear %s" % spec.recruitment_stage
	elif spec is RangerSpec and not spec.recruitment_stage.is_empty():
		return "Clear %s" % spec.recruitment_stage
	return "Unlock pending"
