class_name DeployableUpgradePage
extends VBoxContainer

signal sound_requested(id: String)

signal back_requested

const PORTRAIT := preload("res://scripts/ui/deployment_portrait.gd")

var progress: CampaignProgress
var definition: DeploymentSpec
var _balance: Label
var _current: Label
var _target_level: Label
var _preview: Label
var _price: Label
var _notice: Label
var _buy: Button
var _down: Button
var _up: Button
var _milestones: Dictionary[int, Button]
var _dialog: ConfirmationDialog
var _target := 1

func _ready() -> void:
	theme = HeadquartersArt.THEME
	add_theme_constant_override("separation", 12)
	var back := StoryUI.header(self, definition.label, func() -> void: back_requested.emit(), "Funds")
	back.custom_minimum_size.y = 64
	_balance = back.get_parent().get_node("FundsSummary")

	var levels := StoryUI.panel(self)
	var selector := StoryUI.row(levels, 10)
	_down = StoryUI.action("−")
	_down.name = "LowerTarget"
	_down.accessibility_name = "Lower target level"
	_down.custom_minimum_size = Vector2(104, 64)
	_down.pressed.connect(func() -> void: _set_target(_target - 1))
	selector.add_child(_down)
	_target_level = StoryUI.label("", 22)
	_target_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selector.add_child(_target_level)
	_up = StoryUI.action("+")
	_up.name = "RaiseTarget"
	_up.accessibility_name = "Raise target level"
	_up.custom_minimum_size = _down.custom_minimum_size
	_up.pressed.connect(func() -> void: _set_target(_target + 1))
	selector.add_child(_up)
	var steps := StoryUI.row(levels, 10)
	for level: int in DeployableLevels.MILESTONES:
		var milestone := StoryUI.action(str(level))
		milestone.name = "Milestone%d" % level
		milestone.accessibility_name = "Target level %d" % level
		milestone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		milestone.custom_minimum_size.y = 64
		milestone.toggle_mode = true
		milestone.pressed.connect(func() -> void: _set_target(level))
		steps.add_child(milestone)
		_milestones[level] = milestone

	var body := StoryUI.row(self, 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var current := StoryUI.scroll_column(StoryUI.panel(body, true))
	var heading := StoryUI.row(current, 10)
	var icon := PORTRAIT.new()
	icon.spec = definition
	icon.badge = CampaignVisualAssets.new().badge(definition.id)
	icon.custom_minimum_size = Vector2(72, 72)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(icon)
	var current_heading := StoryUI.label("Current", 26, StoryUI.INK)
	current_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(current_heading)
	_current = StoryUI.label("", 22, StoryUI.INK)
	current.add_child(_current)
	current.add_child(StoryUI.label(_footprint(), 19, StoryUI.INK))
	if definition.growth == null:
		var pending := "Other stat growth values await review." if definition.logistics_post else "Stat growth values await review."
		current.add_child(StoryUI.label(pending, 18, StoryUI.INK))
	if not progress.owns(definition.id):
		current.add_child(StoryUI.label(HeadquartersRosterPage.lock_message(definition), 19, StoryUI.INK))

	var selection := StoryUI.scroll_column(StoryUI.panel(body))
	selection.add_child(StoryUI.label("After upgrade", 26))
	_preview = StoryUI.label("", 22)
	selection.add_child(_preview)
	_notice = StoryUI.label("", 18, StoryUI.AMBER)
	add_child(_notice)
	var footer := StoryUI.row(self, 16)
	_price = StoryUI.label("", 20, StoryUI.BEIGE)
	_price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_price)
	_buy = StoryUI.action("Buy levels", true)
	_buy.name = "BuyLevels"
	_buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy.custom_minimum_size.y = 76
	_buy.pressed.connect(_ask)
	footer.add_child(_buy)
	_dialog = HeadquartersArt.confirmation(self, "Confirm level purchase", "Confirm upgrade")
	_dialog.confirmed.connect(_purchase)
	_set_target(progress.deployable_level(definition.id) + 1)

func _set_target(level: int) -> void:
	var current := progress.deployable_level(definition.id)
	var first := mini(current + 1, DeployableLevels.MAX_LEVEL)
	_target = clampi(level, first, DeployableLevels.MAX_LEVEL)
	_balance.text = "%s Funds" % StoryUI.funds(progress.funds())
	_current.text = "Level %d / %d\n%s" % [current, DeployableLevels.MAX_LEVEL, _stat_summary(current)]
	_target_level.text = "Target level %d" % _target
	_preview.text = _stat_summary(_target)
	if definition.logistics_post and _target > current:
		var extra := _post_yield(_target) - _post_yield(current)
		_preview.text += "\n+%s Tokens per 10 s on average" % String.num(extra, 2).trim_suffix(".0")
	_down.disabled = _target <= first
	_up.disabled = _target >= DeployableLevels.MAX_LEVEL
	for step in _milestones:
		_milestones[step].disabled = step <= current
		_milestones[step].set_pressed_no_signal(step == _target)
	var quote := progress.level_quote(definition.id, _target)
	_buy.disabled = not quote.error.is_empty()
	if current >= DeployableLevels.MAX_LEVEL:
		_price.text = "Maximum level"
	else:
		_price.text = "Cost %s Funds" % StoryUI.funds(quote.cost)
		if quote.balance >= 0:
			_price.text += "\nAfter purchase %s Funds" % StoryUI.funds(quote.balance)
		if not quote.error.is_empty():
			_price.text += "\n" + quote.error
	_notice.visible = not _notice.text.is_empty()

func _stat_summary(level: int) -> String:
	var spec := DeployableLevels.effective(definition, level)
	var stats := PackedStringArray(["%d HP" % spec.max_hp])
	if spec is RangerSpec:
		_append_ranger_stats(stats, spec)
	elif spec is FacilitySpec:
		stats.append(_facility_output(spec))
	return "\n".join(stats)

func _append_ranger_stats(stats: PackedStringArray, spec: RangerSpec) -> void:
	var records_earned := spec.records_enhancement in progress.records_enhancements()
	if records_earned and spec.records_bonus_hp > 0:
		stats.append("+%d HP from Records" % spec.records_bonus_hp)
	if spec.attack_damage > 0:
		stats.append("%d damage per %s s" % [spec.attack_damage, str(spec.attack_seconds)])
	if spec.heal_hp > 0:
		stats.append("%d HP healed per action" % spec.heal_hp)
	if spec.repair_hp > 0:
		stats.append("%d HP repaired per action" % spec.repair_hp)
	var skill := spec.active_skill
	if skill != null and (skill.damage > 0 or skill.healing > 0):
		var status := " (Records locked)" if skill.requires_records and not records_earned else ""
		if skill.damage > 0:
			stats.append("%s · %d damage%s" % [skill.label, skill.damage, status])
		if skill.healing > 0:
			stats.append("%s · %d HP healed%s" % [skill.label, skill.healing, status])
	match spec.field_kit:
		RangerSpec.FieldKit.TRACKER:
			stats.append("%d net damage" % spec.field_damage)
		RangerSpec.FieldKit.SABOTEUR:
			stats.append("%d retreat pulse damage" % spec.field_damage)
		RangerSpec.FieldKit.STRIKE:
			var damage := PackedStringArray()
			for rank in spec.arrival_max_escalations + 1:
				damage.append(str(spec.field_damage + rank * spec.arrival_damage_step))
			stats.append("%s arrival damage per target" % " / ".join(damage))

func _facility_output(spec: FacilitySpec) -> String:
	match spec.role:
		FacilitySpec.Role.LOGISTICS_POST:
			return "%s Tokens per 10 s on average" % String.num(_post_yield(spec.level), 2).trim_suffix(".0")
		FacilitySpec.Role.MEDIC_CABIN:
			return "%d HP healed per kit" % spec.heal_per_kit
		FacilitySpec.Role.SKILL_RELAY:
			return "%s s less skill recharge per pulse" % String.num(spec.cooldown_reduction_seconds, 2)
		FacilitySpec.Role.DISPATCH_RELAY:
			return "%s s less deployment cooldown per pulse" % String.num(spec.cooldown_reduction_seconds, 2)
		FacilitySpec.Role.SONIC_TURRET:
			return "%d damage per sonic pulse" % spec.attack_damage
		FacilitySpec.Role.ELECTRIC_TURRET:
			return "%d base damage per hit" % spec.attack_damage
		FacilitySpec.Role.CANOPY_LAUNCHER:
			return "%d base damage per shot" % spec.attack_damage
		FacilitySpec.Role.SENTRY_TOWER:
			return "%d tile detection radius" % spec.detection_radius
		FacilitySpec.Role.FIREBREAK:
			return "%d%% less Heat generation" % spec.heat_slow_percent
		FacilitySpec.Role.SPECIALIST_CALLTOWER:
			return "%d Token discount per claim" % spec.discount_tokens
		FacilitySpec.Role.COORDINATION_HUB:
			return "%d%% faster attack rate in range" % spec.attack_rate_bonus_percent
		FacilitySpec.Role.REINFORCED_COVER:
			return "%d%% less incoming damage in range" % spec.incoming_reduction_percent
		FacilitySpec.Role.DISRUPTION:
			return "%d%% less damage from enemies in range" % spec.outgoing_reduction_percent
	return ""

func _post_yield(level: int) -> float:
	return LogisticsRules.new().post_yield_numerator(level) / float(LogisticsRules.YIELD_DENOMINATOR)

func _footprint() -> String:
	match definition.kind:
		DeploymentSpec.Kind.GROUND:
			return "One ground tile"
		DeploymentSpec.Kind.GROUND_PAIR:
			return "Two adjacent ground tiles"
		DeploymentSpec.Kind.ELEVATED:
			return "One elevated tile"
		DeploymentSpec.Kind.FACILITY_PAIR:
			return "Two adjacent elevated tiles"
		DeploymentSpec.Kind.SENTRY:
			return "One elevated tile with clearance above"
	return ""

func _ask() -> void:
	var quote := progress.level_quote(definition.id, _target)
	if not quote.error.is_empty():
		sound_requested.emit("ui_invalid")
		_notice.text = quote.error
		_notice.show()
		return
	_dialog.dialog_text = "Confirm level purchase\n\n%s · Level %d → %d\nCost %s Funds\nBalance after purchase %s Funds" % [
		definition.label, quote.current, quote.target, StoryUI.funds(quote.cost), StoryUI.funds(quote.balance),
	]
	_dialog.popup_centered(Vector2i(590, 264))
	_dialog.get_cancel_button().grab_focus()

func _purchase() -> void:
	var previous := progress.deployable_level(definition.id)
	var error := progress.purchase_levels(definition.id, _target)
	if error.is_empty():
		var milestone := floori(_target / 20.0) > floori(previous / 20.0)
		sound_requested.emit("progression_level_milestone" if milestone else "progression_level_purchase")
	else:
		sound_requested.emit("ui_invalid")
	_notice.text = "Reached Level %d." % _target if error.is_empty() else error
	_set_target(progress.deployable_level(definition.id) + 1 if error.is_empty() else _target)
