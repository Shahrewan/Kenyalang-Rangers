class_name LoadoutPicker
extends HBoxContainer

signal selection_changed
signal selection_blocked(message: String)
signal headquarters_requested

var plan: OperationPlan
var _ranger_heading: Label
var _facility_heading: Label
var _buttons: Dictionary[DeploymentSpec, CheckBox] = {}
var _assets: CampaignVisualAssets

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	if not plan.chaos and FirstContactSkin.illustrates_operation(plan.operation.stage.stage_id) 			and not FirstContactSkin.is_pilot(plan.operation.stage.stage_id):
		_assets = CampaignVisualAssets.new()
	var rangers := StoryUI.panel(self, true)
	var facilities := StoryUI.panel(self, true)
	_ranger_heading = StoryUI.label("Rangers", 24, StoryUI.INK)
	rangers.add_child(_ranger_heading)
	_facility_heading = StoryUI.label("Facilities", 24, StoryUI.INK)
	facilities.add_child(_facility_heading)
	if not plan.operation.campaign_spec:
		_legacy(rangers, facilities)
		return
	for spec in plan.deployment_entries():
		if spec.id not in plan.operation.supply_ids:
			continue
		var panel := rangers if spec.is_ranger() else facilities
		var price := "free first drop" if spec.logistics_post else "%d Tokens" % spec.cost
		var label := "Starter Post" if spec.logistics_post else spec.label
		_add_choice(panel, spec, StoryUI.label("%s · %s\nMission supply" % [label, price], 18, StoryUI.INK))
	if plan.operation.opening_rules.starter_only:
		return
	for spec in plan.choices:
		var panel := rangers if spec.is_ranger() else facilities
		var choice := CheckBox.new()
		choice.add_theme_font_size_override("font_size", 16)
		choice.add_theme_color_override("font_color", StoryUI.INK)
		choice.add_theme_color_override("font_hover_color", StoryUI.INK)
		choice.add_theme_color_override("font_pressed_color", StoryUI.INK)
		choice.name = "Equip_" + String(spec.id).replace(".", "_")
		choice.button_pressed = spec.id in plan.selected_ids
		choice.toggled.connect(_toggle.bind(spec, choice))
		_add_choice(panel, spec, choice)
		_buttons[spec] = choice
	if plan.facility_limit == 0 or plan.chaos:
		var access := StoryUI.action("Open Headquarters")
		access.name = "OpenHeadquarters"
		facilities.add_child(access)
		access.pressed.connect(func() -> void: headquarters_requested.emit())
	refresh(plan.resolved())

func _add_choice(panel: Container, spec: DeploymentSpec, control: Control) -> void:
	var badge := _assets.badge(spec.id) if _assets != null else null
	if badge == null:
		panel.add_child(control)
		return
	var row := StoryUI.row(panel, 4)
	var art := TextureRect.new()
	art.texture = badge
	art.custom_minimum_size = Vector2(29, 29)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(art)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)

func refresh(result: ModifierResolution) -> void:
	if not plan.operation.campaign_spec or plan.operation.opening_rules.starter_only:
		return
	_ranger_heading.text = "Rangers · %d/%d" % [plan.selected_count(true), plan.ranger_limit]
	_facility_heading.text = "Facilities · %d/%d" % [result.facility_slots, plan.facility_limit]
	for spec: DeploymentSpec in _buttons:
		var effective := plan.effective_spec(spec)
		var price := "free first drop" if spec.logistics_post else "%d Tokens" % effective.cost
		if spec.logistics_post and result.opening != null and result.opening.fixed_stockpile:
			price = "Excluded by Fixed Stockpile"
		_buttons[spec].text = "%s\nLv.%d · %s" % [spec.label, effective.level, price]

func _toggle(selected: bool, spec: DeploymentSpec, button: CheckBox) -> void:
	if not plan.select_unit(spec, selected):
		button.set_pressed_no_signal(false)
		selection_blocked.emit("Remove an equipped %s to free a slot." % ("Ranger" if spec.is_ranger() else "Facility"))
		return
	selection_changed.emit()

func _legacy(rangers: VBoxContainer, facilities: VBoxContainer) -> void:
	for spec in plan.deployment_entries():
		if spec.is_ranger():
			rangers.add_child(StoryUI.label("%s · %d Tokens" % [spec.label, spec.cost], 18, StoryUI.INK))
		else:
			facilities.add_child(StoryUI.label("Starter Post · Free", 18, StoryUI.INK))
	facilities.add_child(StoryUI.label("Mission supply · Regular slots require Mechanical.", 16, StoryUI.INK))
