class_name DeployableUpgradePage
extends VBoxContainer

signal back_requested

const PORTRAIT := preload("res://scripts/ui/deployment_portrait.gd")

var progress: CampaignProgress
var definition: DeploymentSpec
var _balance: Label
var _current: Label
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
	add_theme_constant_override("separation", 12)
	var back := StoryUI.header(self, definition.label, func() -> void: back_requested.emit(), "Funds")
	_balance = back.get_parent().get_node("FundsSummary")
	var body := StoryUI.row(self, 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var current := StoryUI.panel(StoryUI.scroll_column(body), true)
	var heading := StoryUI.row(current, 10)
	var icon := PORTRAIT.new()
	icon.spec = definition
	icon.badge = CampaignVisualAssets.new().badge(definition.id)
	icon.custom_minimum_size = Vector2(72, 72)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(icon)
	heading.add_child(StoryUI.label("Current", 26, StoryUI.INK))
	_current = StoryUI.label("", 22, StoryUI.INK)
	current.add_child(_current)
	current.add_child(StoryUI.label(_footprint(), 19, StoryUI.INK))
	if DeployableLevels.pending_kit(definition.id):
		current.add_child(StoryUI.label("Combat kit pending", 18, StoryUI.INK))
	if definition.growth == null:
		var pending := "Other stat growth values await review." if definition.logistics_post else "Stat growth values await review."
		current.add_child(StoryUI.label(pending, 18, StoryUI.INK))
	if not progress.owns(definition.id):
		current.add_child(StoryUI.label(HeadquartersRosterPage.lock_message(definition), 19, StoryUI.INK))

	var selection := StoryUI.panel(StoryUI.scroll_column(body))
	var selector := StoryUI.row(selection, 8)
	_down = StoryUI.action("−")
	_down.name = "LowerTarget"
	_down.pressed.connect(func() -> void: _set_target(_target - 1))
	selector.add_child(_down)
	_preview = StoryUI.label("", 22)
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.add_child(_preview)
	_up = StoryUI.action("+")
	_up.name = "RaiseTarget"
	_up.pressed.connect(func() -> void: _set_target(_target + 1))
	selector.add_child(_up)
	var steps := StoryUI.row(selection, 6)
	for level: int in DeployableLevels.MILESTONES:
		var milestone := StoryUI.action(str(level))
		milestone.name = "Milestone%d" % level
		milestone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		milestone.pressed.connect(func() -> void: _set_target(level))
		steps.add_child(milestone)
		_milestones[level] = milestone
	_price = StoryUI.label("", 20, StoryUI.BEIGE)
	selection.add_child(_price)
	_buy = StoryUI.action("Buy levels", true)
	_buy.name = "BuyLevels"
	_buy.pressed.connect(_ask)
	selection.add_child(_buy)
	_notice = StoryUI.label("", 18, StoryUI.AMBER)
	add_child(_notice)
	_dialog = StoryUI.confirmation(self, "Confirm level purchase", "Confirm upgrade")
	_dialog.confirmed.connect(_purchase)
	_set_target(progress.deployable_level(definition.id) + 1)

func _set_target(level: int) -> void:
	var current := progress.deployable_level(definition.id)
	var first := mini(current + 1, DeployableLevels.MAX_LEVEL)
	_target = clampi(level, first, DeployableLevels.MAX_LEVEL)
	_balance.text = "%s Funds" % StoryUI.funds(progress.funds())
	_current.text = _stat_summary(current)
	_preview.text = _stat_summary(_target)
	_down.disabled = _target <= first
	_up.disabled = _target >= DeployableLevels.MAX_LEVEL
	for step in _milestones:
		_milestones[step].disabled = step <= current
	var quote := progress.level_quote(definition.id, _target)
	_buy.disabled = not quote.error.is_empty()
	if current >= DeployableLevels.MAX_LEVEL:
		_price.text = "Maximum level"
	else:
		_price.text = "%s Funds" % StoryUI.funds(quote.cost)
		if not quote.error.is_empty():
			_price.text += "\n" + quote.error

func _stat_summary(level: int) -> String:
	var spec := DeployableLevels.effective(definition, level)
	var stats := PackedStringArray(["Level %d / %d" % [level, DeployableLevels.MAX_LEVEL], "%d HP" % spec.max_hp])
	if spec.attack_damage > 0:
		stats.append("%d damage per %s s" % [spec.attack_damage, str(spec.attack_seconds)])
	if spec.logistics_post:
		var yield_rate := LogisticsRules.new().post_yield_numerator(level) / float(LogisticsRules.YIELD_DENOMINATOR)
		stats.append("%s Tokens per 10 s" % String.num(yield_rate, 2))
	if spec is RangerSpec:
		if spec.heal_hp > 0:
			stats.append("%d HP healed per action" % spec.heal_hp)
		if spec.repair_hp > 0:
			stats.append("%d HP repaired per action" % spec.repair_hp)
	elif spec is FacilitySpec and spec.heal_per_kit > 0:
		stats.append("%d HP healed per kit" % spec.heal_per_kit)
	return "\n".join(stats)

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
		_notice.text = quote.error
		return
	_dialog.dialog_text = "%s · Level %d → %d\nCost %s Funds\nBalance after purchase %s Funds" % [
		definition.label, quote.current, quote.target, StoryUI.funds(quote.cost), StoryUI.funds(quote.balance),
	]
	_dialog.popup_centered()

func _purchase() -> void:
	var error := progress.purchase_levels(definition.id, _target)
	_notice.text = "Reached Level %d." % _target if error.is_empty() else error
	_set_target(progress.deployable_level(definition.id) + 1 if error.is_empty() else _target)
