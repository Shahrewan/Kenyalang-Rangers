extends VBoxContainer

signal planning_requested
signal story_requested

var report: Dictionary

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	StoryUI.header(self, "%s   %s" % [report.stage_id, report.title], func() -> void: story_requested.emit(), "%d Funds" % report.balance)
	var body := StoryUI.row(self, 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var result := StoryUI.panel(body, true)
	var state: String = report.outcome
	var successful := state != "Defeat"
	result.add_child(StoryUI.label(state, 40, StoryUI.INK))
	var explanation := "No combat enemies escaped." if state == "Perfect clear" else "%d combat enemies escaped." % report.escaped
	if not successful:
		explanation = "Operational Integrity reached zero."
	result.add_child(StoryUI.label(explanation, 21, StoryUI.INK))
	var columns := StoryUI.row(result, 14)
	for metric in [["Integrity", report.integrity], ["Defeated", report.defeated], ["Escaped", report.escaped]]:
		var group := StoryUI.column(columns, 4)
		group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group.add_child(StoryUI.label(String(metric[0]), 18, StoryUI.INK))
		group.add_child(StoryUI.label(str(metric[1]), 34, StoryUI.INK))
	var rewards := StoryUI.panel(body)
	rewards.add_child(StoryUI.label("Funds", 28))
	if report.save_failed:
		rewards.add_child(StoryUI.label("Progress could not be saved. The local balance is unchanged.", 20))
	elif successful:
		rewards.add_child(StoryUI.label("First clear   +%d" % report.clear_funds, 22))
		rewards.add_child(StoryUI.label("First perfect   +%d" % report.perfect_funds, 22))
		rewards.add_child(StoryUI.label("Provisional credit   +%d Funds" % (report.clear_funds + report.perfect_funds), 21, StoryUI.AMBER))
	else:
		rewards.add_child(StoryUI.label("No Funds awarded for defeat.", 21))

	var footer := StoryUI.row(self, 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	var story := StoryUI.action("Back to Story")
	story.pressed.connect(func() -> void: story_requested.emit())
	footer.add_child(story)
	var retry := StoryUI.action("Review plan", true)
	retry.name = "ReviewPlan"
	retry.pressed.connect(func() -> void: planning_requested.emit())
	footer.add_child(retry)
	retry.grab_focus()
