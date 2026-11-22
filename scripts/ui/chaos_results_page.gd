class_name ChaosResultsPage
extends VBoxContainer

signal routes_requested
signal review_requested
signal retry_save_requested

var run: ChaosRun
var progress: CampaignProgress
var settlement: Dictionary
var _discard: ConfirmationDialog

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	StoryUI.header(self, run.route_label, request_back, "%s Funds" % StoryUI.funds(progress.funds()))
	var panes := StoryUI.row(self, 14)
	panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var results := StoryUI.panel(StoryUI.scroll_column(panes), true)
	var heading := StoryUI.label(_title(), 32, StoryUI.INK)
	heading.name = "ChaosResultTitle"
	results.add_child(heading)
	results.add_child(StoryUI.label("Integrity %d · Defeated %d/%d · Escaped %d" % [
		run.integrity, run.configured_defeated, run.score.configured_enemies, run.escaped,
	], 19, StoryUI.INK))
	results.add_child(StoryUI.label("%s Medal Score" % StoryUI.funds(run.score.points()), 28, StoryUI.INK))
	results.add_child(StoryUI.label(ChaosComposer.score_breakdown(run.score), 18, StoryUI.INK))

	var rewards := StoryUI.panel(StoryUI.scroll_column(panes))
	if settlement.is_empty():
		rewards.add_child(StoryUI.label("Result could not be saved. Check local storage and retry.", 21, StoryUI.AMBER))
	else:
		var credit := StoryUI.label("%s Funds credited" % StoryUI.funds(settlement.credited), 25, StoryUI.AMBER)
		credit.name = "ChaosCreditedFunds"
		rewards.add_child(credit)
		if settlement.discarded > 0:
			rewards.add_child(StoryUI.label("%s Funds discarded above the wallet cap." % StoryUI.funds(settlement.discarded), 18, StoryUI.BEIGE))
		if settlement.new_best:
			rewards.add_child(StoryUI.label("New personal best", 19))
		if not settlement.unlocked.is_empty():
			rewards.add_child(StoryUI.label("Facility unlocks", 21))
			for id: StringName in settlement.unlocked:
				rewards.add_child(StoryUI.label(DeployableLevels.definition(id).label, 18, StoryUI.BEIGE))
	var trophy := ChaosTrophy.new()
	trophy.personal_best = progress.chaos_personal_best()
	rewards.add_child(trophy)

	var actions := StoryUI.row(self)
	actions.alignment = BoxContainer.ALIGNMENT_END
	if settlement.is_empty():
		_discard = StoryUI.confirmation(self, "Return without saving this result?", "Discard result")
		_discard.confirmed.connect(func() -> void: routes_requested.emit())
		_action(actions, "Return without saving", "DiscardChaosResult", request_back)
		_action(actions, "Retry save", "RetryChaosSave", func() -> void: retry_save_requested.emit(), true)
	else:
		_action(actions, "Back to routes", "ChaosRoutes", request_back)
		_action(actions, "Review configuration", "ReviewChaos", func() -> void: review_requested.emit(), true)

func request_back() -> void:
	if _discard != null:
		_discard.popup_centered()
	else:
		routes_requested.emit()

func _title() -> String:
	if run.lost:
		return "Defeat"
	if run.escaped > 0:
		return "Escape · No payout"
	return "Qualifying clear" if run.qualifies() else "Incomplete · No payout"

func _action(actions: Container, text: String, id: String, callback: Callable, primary := false) -> void:
	var button := StoryUI.action(text, primary)
	button.name = id
	button.pressed.connect(callback)
	actions.add_child(button)
