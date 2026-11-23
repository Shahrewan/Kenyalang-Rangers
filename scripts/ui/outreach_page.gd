class_name OutreachPage
extends VBoxContainer

signal sound_requested(id: String)
signal back_requested

var progress: CampaignProgress
var catalog: EducationCatalog
var _session: OutreachSession
var _selected := ""
var _timer: Label
var _progress_label: Label
var _refresh: Button
var _tabs: HBoxContainer
var _body: VBoxContainer
var _wallet: Label
var _notice: Label
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
	_refresh = StoryUI.action("Refresh batch")
	_refresh.name = "RefreshOutreach"
	_refresh.pressed.connect(_open_batch)
	status.add_child(_refresh)
	_tabs = StoryUI.row(self)
	_body = StoryUI.scroll_column(self)
	_progress_label = StoryUI.label("", 18, StoryUI.BEIGE)
	_progress_label.name = "OutreachParticipation"
	add_child(_progress_label)
	_notice = StoryUI.label("", 18, StoryUI.AMBER)
	add_child(_notice)
	_session = OutreachSession.new(progress, catalog)
	_open_batch()

func _open_batch() -> void:
	_notice.text = ""
	var before: int = int(_session.batch().refreshed_at)
	if not catalog.outreach.is_empty() and not _session.refresh(_now()):
		_notice.text = "Could not open the batch. Check local storage and retry."
	if int(_session.batch().refreshed_at) != before:
		_selected = ""
	_render()

func _render() -> void:
	_wallet.text = "%s Funds" % StoryUI.funds(progress.funds())
	_progress_label.text = "%d Best or Acceptable responses · 5 needed for Outreach Lv.5" % progress.outreach_successes()
	EducationUI.clear(_tabs)
	EducationUI.clear(_body)
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
		var choice := StoryUI.action("%d%s" % [index + 1, " ✓" if batch.responses.has(id) else ""], id == _selected)
		choice.name = "OutreachPrompt%d" % (index + 1)
		choice.pressed.connect(_select.bind(id))
		_tabs.add_child(choice)
	var question: Dictionary = catalog.outreach[_selected]
	var card := StoryUI.panel(_body, true)
	card.add_child(StoryUI.label("Operations Manager", 18, StoryUI.INK))
	var prompt := StoryUI.label(question.prompt, 24, StoryUI.INK)
	prompt.name = "OutreachPrompt"
	card.add_child(prompt)
	if batch.responses.has(_selected):
		_review(card, question, batch.responses[_selected])
	else:
		var order: Array = batch.choice_order[_selected]
		for index in order.size():
			var answer: Dictionary = question.choices[int(order[index])]
			_body.add_child(EducationUI.answer_button(answer.text, "OutreachAnswer%d" % index, _submit.bind(_selected, index)))
	StoryUI.size_buttons(self)

func _select(id: String) -> void:
	_selected = id
	_notice.text = ""
	_render()

func _submit(question: String, option: int) -> void:
	if question != _selected:
		return
	var now := _now()
	if _session.seconds_until_refresh(now) == 0:
		_open_batch()
		return
	if _session.submit(question, option, now).is_empty():
		_notice.text = "Could not save this response. Check local storage and retry."
	else:
		sound_requested.emit("education")
		_notice.text = ""
		_render()

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
