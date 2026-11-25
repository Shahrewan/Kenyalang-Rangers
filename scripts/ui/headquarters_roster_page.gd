class_name HeadquartersRosterPage
extends VBoxContainer

signal back_requested
signal unit_requested(spec: DeploymentSpec)

const PORTRAIT := preload("res://scripts/ui/deployment_portrait.gd")

var rangers := true
var progress: CampaignProgress
var _art := CampaignVisualAssets.new()

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var title := "Ranger upgrades" if rangers else "Facility upgrades"
	StoryUI.header(self, title, func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
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
	var tile := StoryUI.panel(grid, true)
	var status := StoryUI.row(tile, 10)
	var icon := PORTRAIT.new()
	icon.spec = spec
	icon.badge = _art.badge(spec.id)
	icon.custom_minimum_size = Vector2(44, 44)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_child(icon)
	var level := "Level %d" % progress.deployable_level(spec.id) if owned else "Locked"
	var title := StoryUI.label("%s · %s" % [spec.label, level], 20, StoryUI.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(title)
	var detail := lock_message(spec) if not owned else ""
	if not detail.is_empty():
		tile.add_child(StoryUI.label(detail, 17, StoryUI.INK))
	var open := StoryUI.action("Review levels" if owned else "View details")
	open.name = "Unit_" + String(spec.id).get_slice(".", 1)
	open.pressed.connect(func() -> void: unit_requested.emit(spec))
	tile.add_child(open)

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
