class_name OutreachPage
extends VBoxContainer

signal sound_requested(id: String)
signal back_requested

const REACTIONS := {
	"best": preload("res://assets/imported/portraits/manager/outreach_best.png"),
	"acceptable": preload("res://assets/imported/portraits/manager/outreach_acceptable.png"),
	"poor": preload("res://assets/imported/portraits/manager/outreach_poor.png"),
	"harmful": preload("res://assets/imported/portraits/manager/outreach_harmful.png"),
}

var progress: CampaignProgress
var catalog: EducationCatalog
var _session: OutreachSession
var _selected := ""
var _timer: Label
var _progress_label: Label
var _refresh: Button
var _tabs: HBoxContainer
var _context: VBoxContainer
var _body: VBoxContainer
var _wallet: Label
var _notice: Label
var _next: Button
var _next_prompt := ""
var _last_checked := -1

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var back := StoryUI.header(self, "Outreach", func() -> void: back_requested.emit(), "Funds")
	_wallet = back.get_parent().get_node("FundsSummary")
	var status := StoryUI.row(self)
	_timer = StoryUI.label("", 20, StoryUI.AMBER)
	_timer.name = "OutreachTimer"
	_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(_timer)
	_refresh = EducationUI.large_action(StoryUI.action("Refresh batch"))
	_refresh.name = "RefreshOutreach"
	_refresh.pressed.connect(_open_batch.bind(true))
	status.add_child(_refresh)
	_tabs = StoryUI.row(self)
	var columns := EducationUI.activity_body(self)
	_context = columns[0]
	_body = columns[1]
	var footer := StoryUI.row(self, 12)
	_progress_label = StoryUI.label("", 18, StoryUI.BEIGE)
	_progress_label.name = "OutreachParticipation"
	_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_progress_label)
	_next = EducationUI.large_action(StoryUI.action("Next unanswered", true))
	_next.name = "NextOutreachPrompt"
	_next.custom_minimum_size.x = 240
	_next.pressed.connect(func() -> void: _select(_next_prompt))
	footer.add_child(_next)
	_notice = StoryUI.label("", 18, StoryUI.AMBER)
	add_child(_notice)
	_session = OutreachSession.new(progress, catalog)
	_open_batch()

func _open_batch(explicit := false) -> void:
	_show_notice("")
	var before: int = int(_session.batch().refreshed_at)
	if not catalog.outreach.is_empty() and not _session.refresh(_now()):
		_show_notice("Could not open the batch. Check local storage and retry.")
	if int(_session.batch().refreshed_at) != before:
		_selected = ""
		if explicit:
			sound_requested.emit("outreach_batch_refresh")
	_render()

func _render() -> void:
	_wallet.text = "%s Funds" % StoryUI.funds(progress.funds())
	_progress_label.text = "%d Best or Acceptable responses · 5 needed for Outreach Lv.5" % progress.outreach_successes()
	EducationUI.clear(_tabs)
	EducationUI.clear(_context)
	EducationUI.clear(_body)
	_context.get_parent().scroll_vertical = 0
	_body.get_parent().scroll_vertical = 0
	_context.get_parent().hide()
	_next.hide()
	_next_prompt = ""
	if catalog.outreach.is_empty():
		_timer.text = ""
		_refresh.hide()
		_body.add_child(StoryUI.label("Outreach questions await an approved bank.", 23))
		return
	var batch := _session.batch()
	_update_timer(_now())
	if not _session.matches_bank(batch):
		var message := "Select Refresh batch to open your questions." if batch.batch.is_empty() else "An updated bank will open at the next eligible refresh."
		_body.add_child(StoryUI.label(message, 21))
		return

	if _selected not in batch.batch:
		_selected = batch.batch[0]
		for id: String in batch.batch:
			if not batch.responses.has(id):
				_selected = id
				break
	for index in batch.batch.size():
		var id: String = batch.batch[index]
		var answered: bool = batch.responses.has(id)
		var choice := EducationUI.large_action(StoryUI.action("%d%s" % [index + 1, " ✓" if answered else ""], id == _selected))
		choice.tooltip_text = "Scenario %d · %s" % [index + 1, "Answered" if answered else "Pending"]
		choice.accessibility_name = choice.tooltip_text
		choice.name = "OutreachPrompt%d" % (index + 1)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.pressed.connect(_select.bind(id))
		_tabs.add_child(choice)
	var question: Dictionary = catalog.outreach[_selected]
	var response: Dictionary = batch.responses.get(_selected, {})
	_context.get_parent().show()
	var card := StoryUI.panel(_context, true)
	var portrait: Texture2D = REACTIONS.get(response.get("grade", ""), StoryPortrait.FIRST_CONTACT["portrait.manager"]["briefing"])
	var manager := StoryUI.artwork(portrait, Vector2(104, 104))
	manager.name = "OutreachManagerPortrait"
	card.add_child(manager)
	card.add_child(StoryUI.label("Operations Manager", 18, StoryUI.INK))
	var prompt := StoryUI.label(question.prompt, 24, StoryUI.INK)
	prompt.name = "OutreachPrompt"
	card.add_child(prompt)
	if not response.is_empty():
		_review(StoryUI.panel(_body, true), question, response)
		for id: String in batch.batch:
			if not batch.responses.has(id):
				_next_prompt = id
				_next.show()
				break
	else:
		var order: Array = batch.choice_order[_selected]
		for index in order.size():
			var answer: Dictionary = question.choices[int(order[index])]
			_body.add_child(EducationUI.answer_button(answer.text, "OutreachAnswer%d" % index, _submit.bind(_selected, index)))
	StoryUI.size_buttons(self)

func _select(id: String) -> void:
	_selected = id
	_show_notice("")
	_render()

func _submit(question: String, option: int) -> void:
	if question != _selected:
		return
	var now := _now()
	if _session.seconds_until_refresh(now) == 0:
		_open_batch()
		_show_notice("That batch ended. Choose a response in the new batch.")
		return
	var response := _session.submit(question, option, now)
	if response.is_empty():
		sound_requested.emit("ui_save_problem")
		_show_notice("Could not save this response. Check local storage and retry.")
	else:
		sound_requested.emit("outreach_response_positive" if response.grade in ["best", "acceptable"] else "outreach_response_reflect")
		_show_notice("")
		_render()

func _show_notice(message: String) -> void:
	_notice.text = message
	_notice.visible = not message.is_empty()

func _review(card: VBoxContainer, question: Dictionary, response: Dictionary) -> void:
	var answer: Dictionary = question.choices[int(response.choice)]
	var heading := StoryUI.label(String(response.grade).capitalize(), 24, StoryUI.INK)
	heading.name = "OutreachGrade"
	card.add_child(heading)
	card.add_child(StoryUI.label(answer.text, 19, StoryUI.INK))
	card.add_child(StoryUI.label(answer.justification, 21, StoryUI.INK))
	var funds := StoryUI.label(EducationUI.receipt(int(response.change), int(response.get("discarded", 0))), 19, StoryUI.INK)
	funds.name = "OutreachFundsChange"
	card.add_child(funds)
	EducationUI.credit_sources(card, catalog, question.source_ids, StoryUI.INK)

func _process(_delta: float) -> void:
	if _session != null and not catalog.outreach.is_empty():
		var now := _now()
		if now != _last_checked:
			_update_timer(now)

func _update_timer(now: int) -> void:
	_last_checked = now
	var time := _session.seconds_until_refresh(now)
	_refresh.disabled = time > 0
	var hours := floori(float(time) / 3600.0)
	var minutes := floori(float(time % 3600) / 60.0)
	var countdown := "Next batch in %02dh %02dm %02ds" % [hours, minutes, time % 60]
	var batch := _session.batch()
	var answered := "%d/%d answered · " % [batch.responses.size(), batch.batch.size()] if not batch.batch.is_empty() else ""
	_timer.text = answered + ("New batch ready" if time == 0 else countdown)

func _now() -> int:
	return int(Time.get_unix_time_from_system())
