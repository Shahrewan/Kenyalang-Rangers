class_name RecordsArchivePage
extends VBoxContainer

signal article_requested(id: String)
signal back_requested
signal quiz_requested(quiz: RecordsQuiz)

const CHAPTER_ART := {
	"scout_sniper": preload("res://assets/imported/education/records/scout_sniper.png"),
	"patrolman": preload("res://assets/imported/education/records/patrolman.png"),
	"combat_medic": preload("res://assets/imported/education/records/combat_medic.png"),
	"woods_tracker": preload("res://assets/imported/education/records/woods_tracker.png"),
}

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
	archive.get_parent().size_flags_stretch_ratio = 0.92
	archive.get_parent().scroll_deadzone = 12
	archive.add_child(StoryUI.label("Facts archive", 25))
	if catalog.facts.is_empty():
		archive.add_child(StoryUI.label("The archive is awaiting approved facts.", 20, StoryUI.BEIGE))
	var discoveries := progress.discovered_facts()
	for id: String in catalog.facts:
		var fact: Dictionary = catalog.facts[id]
		var card := StoryUI.panel(archive, true)
		card.get_parent().mouse_filter = Control.MOUSE_FILTER_PASS
		card.add_child(StoryUI.label(fact.title, 22, StoryUI.INK))
		if id in discoveries:
			card.add_child(StoryUI.label("Discovered", 17, StoryUI.INK))
		card.add_child(StoryUI.label(fact.text, 20, StoryUI.INK))
		EducationUI.credit_sources(card, catalog, fact.source_ids, StoryUI.INK)
		var read := EducationUI.large_action(StoryUI.action("Read article"))
		read.mouse_filter = Control.MOUSE_FILTER_PASS
		read.name = "Article_" + id.get_slice(".", 1)
		read.accessibility_name = "Read article · %s" % fact.title
		read.pressed.connect(func() -> void: article_requested.emit(id))
		card.add_child(read)
	var chapters := StoryUI.scroll_column(body)
	chapters.get_parent().size_flags_stretch_ratio = 1.08
	chapters.get_parent().scroll_deadzone = 12
	var heading := StoryUI.label("Quiz chapters", 25)
	chapters.add_child(heading)
	if catalog.chapters.is_empty():
		chapters.add_child(StoryUI.label("Quiz questions await an approved bank.", 20, StoryUI.BEIGE))
	var available := progress.records_chapters()
	var enhanced := progress.records_enhancements()
	var existing := RecordsQuiz.new(progress, catalog)
	for id: String in EducationCatalog.CHAPTERS:
		var mapping: Array = EducationCatalog.CHAPTERS[id]
		var chapter: Dictionary = catalog.chapters.get(id, {})
		var card := StoryUI.panel(chapters)
		card.get_parent().mouse_filter = Control.MOUSE_FILTER_PASS
		var title: String = mapping[0]
		if not chapter.is_empty():
			title += " · " + chapter.topic
		var ranger := StoryUI.row(card, 8)
		var ranger_id := id.get_slice(".", 1)
		var badge := StoryUI.artwork(CHAPTER_ART.get(ranger_id), Vector2(84, 54))
		badge.name = "RecordsChapterArt_" + ranger_id
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ranger.add_child(badge)
		var description := StoryUI.column(ranger, 4)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.add_child(StoryUI.label(title, 22, StoryUI.AMBER))
		description.add_child(StoryUI.label(mapping[1], 18))
		if not chapter.is_empty():
			card.add_child(StoryUI.label("%d questions · 15 s each" % chapter.questions.size(), 17, StoryUI.BEIGE))
		var unlocked := id in available
		var open := EducationUI.large_action(StoryUI.action(
			"Resume chapter" if existing.can_resume() and existing.chapter_id() == id else "Start chapter", true
		))
		open.mouse_filter = Control.MOUSE_FILTER_PASS
		open.name = "Chapter_" + id.get_slice(".", 1)
		open.accessibility_name = "%s · %s" % [open.text, title]
		open.disabled = not unlocked or chapter.is_empty()
		open.pressed.connect(_open.bind(id))
		card.add_child(open)
		if not unlocked:
			var level := EducationCatalog.CHAPTERS.keys().find(id) + 2
			card.add_child(StoryUI.label("Requires Records Lv.%d" % level, 17, StoryUI.BEIGE))
		elif StringName(id) in enhanced:
			card.add_child(StoryUI.label("Enhancement earned", 17, StoryUI.BEIGE))
	_notice = StoryUI.label("", 18, StoryUI.AMBER)
	_notice.hide()
	add_child(_notice)
	_replace = StoryUI.confirmation(self, "Replace saved quiz?", "Start chapter")
	_replace.dialog_text = "The current quiz will close. Earned Funds and enhancements stay in your profile."
	EducationUI.large_action(_replace.get_ok_button())
	EducationUI.large_action(_replace.get_cancel_button())
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
		_notice.show()

func _start(quiz: RecordsQuiz, id: String) -> void:
	if quiz.begin(id):
		quiz_requested.emit(quiz)
	else:
		_notice.text = "Could not start the chapter. Check local storage."
		_notice.show()
