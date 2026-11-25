extends VBoxContainer

signal planning_requested
signal story_requested

var report: Dictionary

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	if report.get("campaign", false) and FirstContactSkin.illustrates_operation(report.stage_id) \
			and not FirstContactSkin.is_pilot(report.stage_id):
		theme = CampaignVisualAssets.THEME
	StoryUI.header(self, "%s   %s" % [report.stage_id, report.title], func() -> void: story_requested.emit(), "%s Funds" % StoryUI.funds(report.balance))
	var body := StoryUI.row(self, 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var result := StoryUI.panel(StoryUI.scroll_column(body), true)
	var state: String = report.outcome
	var successful := state != "Defeat"
	var skin := FirstContactSkin.new()
	if report.get("campaign", false) and FirstContactSkin.illustrates_operation(report.stage_id) and not skin.registration().is_empty():
		var badge := TextureRect.new()
		var artwork := "result_perfect" if report.perfect else ("result_clear" if successful else "result_defeat")
		badge.texture = skin.region("interface", artwork)
		badge.custom_minimum_size.y = 78
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result.add_child(badge)
	result.add_child(StoryUI.label(state, 40, StoryUI.INK))
	var explanation := "No combat enemies escaped." if report.get("perfect", state == "Perfect clear") else "%d combat enemies escaped." % report.escaped
	if not successful:
		explanation = "Operational Integrity reached zero."
		var fatal: String = report.get("fatal_escape_name", "")
		if not fatal.is_empty():
			explanation = "%s escaped through the tunnel. The operation failed immediately." % fatal
	result.add_child(StoryUI.label(explanation, 21, StoryUI.INK))
	var columns := StoryUI.row(result, 14)
	for metric in [["Integrity", report.integrity], ["Defeated", report.defeated], ["Escaped", report.escaped]]:
		var group := StoryUI.column(columns, 4)
		group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group.add_child(StoryUI.label(String(metric[0]), 18, StoryUI.INK))
		group.add_child(StoryUI.label(str(metric[1]), 34, StoryUI.INK))
	var rewards := StoryUI.panel(StoryUI.scroll_column(body))
	rewards.add_child(StoryUI.label("Funds", 28))
	if report.save_failed:
		rewards.add_child(StoryUI.label("Progress could not be saved. The local balance is unchanged.", 20))
	elif successful and report.get("campaign", false):
		_campaign_rewards(rewards)
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

func _campaign_rewards(panel: VBoxContainer) -> void:
	var settlement: Dictionary = report.settlement
	var categories := {
		"first_clear_funds": "First clear",
		"first_perfect_funds": "First perfect",
		"replay_funds": "Replay",
		"story_completion_funds": "Story completion",
	}
	for key: String in categories:
		if settlement.awards.has(key):
			panel.add_child(StoryUI.label("%s   +%s" % [categories[key], StoryUI.funds(settlement.awards[key])], 21))
		elif key in settlement.pending_awards:
			panel.add_child(StoryUI.label("%s · Funds pending review" % categories[key], 20, StoryUI.BEIGE))
	if settlement.credited > 0 or settlement.discarded > 0:
		panel.add_child(StoryUI.label("%s Funds credited" % StoryUI.funds(settlement.credited), 22, StoryUI.AMBER))
	if settlement.discarded > 0:
		panel.add_child(StoryUI.label("%s Funds discarded above the wallet cap." % StoryUI.funds(settlement.discarded), 18, StoryUI.AMBER))
	if not report.unlocked.is_empty():
		panel.add_child(StoryUI.label("Unlocked", 23))
		var assets := CampaignVisualAssets.new()
		var ids: Array = report.get("unlocked_art_ids", [])
		for i in report.unlocked.size():
			var label := StoryUI.label(report.unlocked[i], 19)
			var texture := assets.badge(ids[i]) if i < ids.size() else null
			if texture == null:
				panel.add_child(label)
				continue
			var row := StoryUI.row(panel, 8)
			var badge := TextureRect.new()
			badge.texture = texture
			badge.custom_minimum_size = Vector2(35, 35)
			badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(badge)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
