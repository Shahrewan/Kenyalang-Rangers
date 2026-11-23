class_name RecordsArchivePage
extends VBoxContainer

signal back_requested
signal quiz_requested(quiz: RecordsQuiz)

var progress: CampaignProgress
var catalog: EducationCatalog
var _notice: Label
var _replace: ConfirmationDialog
var _requested_chapter := ""

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	StoryUI.header(self, "Records Encyclopaedia", func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	var body := StoryUI.row(self, 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var archive := StoryUI.scroll_column(body)
	archive.add_child(StoryUI.label("Facts archive", 25))
	if catalog.facts.is_empty():
		archive.add_child(StoryUI.label("The archive is awaiting approved facts.", 20, StoryUI.BEIGE))
	var discoveries := progress.discovered_facts()
	for id: String in catalog.facts:
		var fact: Dictionary = catalog.facts[id]
		var card := StoryUI.panel(archive, true)
		card.add_child(StoryUI.label(fact.title, 22, StoryUI.INK))
		if id in discoveries:
			card.add_child(StoryUI.label("Discovered", 17, StoryUI.INK))
		card.add_child(StoryUI.label(fact.text, 20, StoryUI.INK))
		EducationUI.credit_sources(card, catalog, fact.source_ids, StoryUI.INK)
	var chapters := StoryUI.scroll_column(body)
	var heading := StoryUI.label("Quiz chapters", 25)
	chapters.add_child(heading)
	if catalog.chapters.is_empty():
		chapters.add_child(StoryUI.label("Quiz questions await an approved bank and award values.", 20, StoryUI.BEIGE))
	var available := progress.records_chapters()
	var enhanced := progress.records_enhancements()
	var existing := RecordsQuiz.new(progress, catalog)
	for id: String in EducationCatalog.CHAPTERS:
		var mapping: Array = EducationCatalog.CHAPTERS[id]
		var chapter: Dictionary = catalog.chapters.get(id, {})
		var card := StoryUI.panel(chapters)
		var title: String = mapping[0]
		if not chapter.is_empty():
			title += " · " + chapter.topic
		card.add_child(StoryUI.label(title, 22, StoryUI.AMBER))
		card.add_child(StoryUI.label(mapping[1], 18))
		var unlocked := id in available
		var open := StoryUI.action("Resume chapter" if existing.can_resume() and existing.chapter_id() == id else "Start chapter")
		open.name = "Chapter_" + id.get_slice(".", 1)
		open.disabled = not unlocked or chapter.is_empty()
		open.pressed.connect(_open.bind(id))
		card.add_child(open)
		if not unlocked:
			var level := EducationCatalog.CHAPTERS.keys().find(id) + 2
			card.add_child(StoryUI.label("Requires Records Lv.%d" % level, 17, StoryUI.BEIGE))
		elif StringName(id) in enhanced:
			card.add_child(StoryUI.label("Enhancement earned", 17, StoryUI.BEIGE))
	_notice = StoryUI.label("", 18, StoryUI.AMBER)
	add_child(_notice)
	_replace = StoryUI.confirmation(self, "Replace saved quiz?", "Start chapter")
	_replace.dialog_text = "The current quiz will close. Earned Funds and enhancements stay in your profile."
	_replace.confirmed.connect(_start_replacement)

func _open(id: String) -> void:
	if not id in progress.records_chapters() or not catalog.chapters.has(id):
		return
	var quiz := RecordsQuiz.new(progress, catalog)
	if quiz.can_resume() and quiz.chapter_id() == id:
		quiz_requested.emit(quiz)
	elif progress.quiz_attempt().is_empty():
		_start(quiz, id)
	else:
		_requested_chapter = id
		_replace.popup_centered()

func _start_replacement() -> void:
	if progress.close_quiz():
		_start(RecordsQuiz.new(progress, catalog), _requested_chapter)
	else:
		_notice.text = "Could not replace the saved quiz. Check local storage."

func _start(quiz: RecordsQuiz, id: String) -> void:
	if quiz.begin(id):
		quiz_requested.emit(quiz)
	else:
		_notice.text = "Could not start the chapter. Check local storage."
