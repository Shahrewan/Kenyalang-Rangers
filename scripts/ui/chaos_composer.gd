class_name ChaosComposer
extends VBoxContainer

signal back_requested
signal modifiers_requested
signal headquarters_requested
signal start_requested

var plan: OperationPlan
var configuration: ChaosConfiguration
var progress: CampaignProgress
var show_loadout := false
var initial_slot := 0

var wave_editor: ChaosWaveEditor
var _loadout: LoadoutPicker
var _units: Control
var _wave_tab: Button
var _loadout_tab: Button
var _score: Label
var _payout: Label
var _tier: Label
var _breakdown: Label
var _feedback: Label
var _start: Button

func _ready() -> void:
	add_theme_constant_override("separation", 11)
	StoryUI.header(self, configuration.route_label(), func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	var tabs := StoryUI.row(self)
	var choice := ButtonGroup.new()
	_wave_tab = _tab(tabs, "Waves", "EditWaves", choice, false)
	_loadout_tab = _tab(tabs, "Loadout", "EditLoadout", choice, true)
	var effects := StoryUI.action("Edit modifiers")
	effects.name = "OpenModifiers"
	effects.pressed.connect(func() -> void: modifiers_requested.emit())
	tabs.add_child(effects)

	var panes := StoryUI.row(self, 14)
	panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wave_editor = ChaosWaveEditor.new()
	wave_editor.configuration = configuration
	wave_editor.slot = initial_slot
	wave_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wave_editor.changed.connect(_update_waves)
	panes.add_child(wave_editor)
	var inside := StoryUI.scroll_column(panes)
	_units = inside.get_parent()
	_loadout = LoadoutPicker.new()
	_loadout.plan = plan
	_loadout.selection_changed.connect(_refresh)
	_loadout.selection_blocked.connect(show_error)
	_loadout.headquarters_requested.connect(func() -> void: headquarters_requested.emit())
	inside.add_child(_loadout)
	var right := StoryUI.scroll_column(panes)
	right.get_parent().size_flags_stretch_ratio = 0.51
	right.custom_minimum_size.x = 270
	var card := StoryUI.panel(right, true)
	card.add_child(StoryUI.label("Medal Score", 21, StoryUI.INK))
	_score = StoryUI.label("", 40, StoryUI.INK)
	_score.name = "MedalScore"
	card.add_child(_score)
	_payout = StoryUI.label("", 20, StoryUI.INK)
	_payout.name = "ChaosPayout"
	card.add_child(_payout)
	_tier = StoryUI.label("", 17, StoryUI.INK)
	_tier.name = "ProjectedTrophy"
	card.add_child(_tier)
	_breakdown = StoryUI.label("", 16, StoryUI.INK)
	_breakdown.name = "ScoreBreakdown"
	card.add_child(_breakdown)

	var actions := StoryUI.row(self)
	_feedback = StoryUI.label("", 18, StoryUI.BEIGE)
	_feedback.name = "ChaosFeedback"
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_feedback)
	_start = StoryUI.action("Start challenge", true)
	_start.name = "StartChaos"
	_start.pressed.connect(func() -> void:
		if plan.can_start():
			start_requested.emit()
	)
	actions.add_child(_start)
	_display_tab(show_loadout)
	_refresh()

func _tab(parent: Control, text: String, id: String, choice: ButtonGroup, show_units: bool) -> Button:
	var button := StoryUI.action(text)
	button.name = id
	button.toggle_mode = true
	button.button_group = choice
	button.pressed.connect(_display_tab.bind(show_units))
	parent.add_child(button)
	return button

func _display_tab(units: bool) -> void:
	show_loadout = units
	_wave_tab.set_pressed_no_signal(not units)
	_loadout_tab.set_pressed_no_signal(units)
	wave_editor.visible = not units
	_units.visible = units

func _update_waves() -> void:
	plan.update_stage(configuration.build_stage())
	_refresh()

func _refresh() -> void:
	var resolved := plan.resolved()
	_loadout.refresh(resolved)
	_start.disabled = not resolved.can_start()
	var configs := plan.operation.stage.waves.size()
	if _start.disabled:
		_score.text = "—"
		_payout.text = "Funds on qualifying victory"
		_tier.text = ""
		_breakdown.text = "%d populated · %d empty" % [configs, ChaosConfiguration.WAVE_SLOTS - configs]
		if configs == 0:
			show_error("Add at least one enemy to start.")
		elif not resolved.selection_error.is_empty():
			show_error(resolved.selection_error)
		elif plan.facility_limit == 0:
			show_error("Open Headquarters from Loadout to build Mechanical and equip a Logistics Post.")
		else:
			show_error(resolved.opening_error)
		return
	var score := ChaosScore.new(resolved)
	var points := score.points()
	var gross := ChaosScore.payout(points)
	_score.text = StoryUI.funds(points)
	_payout.text = "%s Funds on qualifying victory" % StoryUI.funds(gross)
	var wallet := FundsWallet.quote(progress.funds(), gross)
	if wallet.discarded > 0:
		_payout.text += "\n%s Funds credited · %s permanently discarded" % [StoryUI.funds(wallet.credited), StoryUI.funds(wallet.discarded)]
	var projected := ChaosScore.tier(maxi(points, progress.chaos_personal_best()))
	_tier.text = "Trophy tier after victory · %d" % projected if projected > 0 else "Trophy · Unranked"
	var enemy_label := "enemy" if score.configured_enemies == 1 else "enemies"
	var wave_label := "wave" if configs == 1 else "waves"
	_breakdown.text = "%d %s · %d populated %s\n%s" % [score.configured_enemies, enemy_label, configs, wave_label, score_breakdown(score)]
	show_error("Opening · %d Tokens" % resolved.tokens)
	if resolved.entries.any(func(spec: DeploymentSpec) -> bool: return spec.logistics_post):
		_feedback.text += " · First Post free"

func show_error(message: String) -> void:
	_feedback.text = message

static func score_breakdown(score: ChaosScore) -> String:
	var parts := PackedStringArray([
		"Enemies  +%s" % StoryUI.funds(score.enemy_points),
		"%d Ranger / %d Facility slots  %s" % [score.ranger_slots, score.facility_slots, StoryUI.funds(score.slot_points())],
		debuff_credit_summary(score),
	])
	if not score.modifiers.is_empty():
		parts.append("Selected modifiers")
	for id: StringName in score.modifiers:
		var title := BattleModifiers.CATALOG.definition(id).display_name
		var amount := score.modifiers[id]
		parts.append("%s  %s%s" % [title, "+" if amount > 0 else "", StoryUI.funds(amount)])
	return "\n".join(parts)

static func debuff_credit_summary(score: ChaosScore) -> String:
	var credit := score.credited_debuff_points()
	if credit < score.debuff_points:
		return "Debuff credit  +%s of +%s (capped)" % [StoryUI.funds(credit), StoryUI.funds(score.debuff_points)]
	return "Debuff credit  +%s (cap %s)" % [StoryUI.funds(credit), StoryUI.funds(score.debuff_cap())]
