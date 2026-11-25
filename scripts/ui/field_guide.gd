class_name FieldGuide
extends VBoxContainer

signal closed

const CREDITS := "Credits and engine license"
const ARTICLE_FRAME := preload("res://assets/imported/education/records/article_frame.png")
const CONTROLS := "Battle controls"
const DEPLOY_TOPIC := "How do I deploy and retreat?"
const ESCAPE_TOPIC := "What happens when enemies escape?"
const TOPICS := {
	DEPLOY_TOPIC: "Swipe across the tray to browse your loadout. Drag a card to a highlighted tile. After its cooldown, use the same card to deploy another copy on a free footprint. For melee Rangers, release on the left or right half to lock facing. Tap a deployed unit to use or arm its skill. Select a tile and confirm targeted skills. Hold a Ranger to reveal Retreat, then release onto it or tap it.",
	ESCAPE_TOPIC: "Combat enemies that reach the tree-veiled tunnel reduce Operational Integrity. At zero Integrity the operation ends in defeat. Pause to inspect the waves and active enemies.",
	"Where do I earn and spend Funds?": "Claim stored Funds in Finance. Operations and side activities can pay Funds. Use them for Headquarters rooms and deployable upgrades. Logistic Tokens pay for deployment during a battle.",
	"How does the garden grow offline?": "Build Ecology to open two plots. Water halfway through the in-game growth time. Collect the mature tree to free the plot. The tree stays in the garden.",
	"How do I change sound or text?": "Open Settings from the Main Menu or the battle pause menu. Adjust Master, Music, Sound effects or Text size. Your choices persist on this device.",
}
const REFERENCES := {
	"https://forestry.sarawak.gov.my/web/subpage/webpage_view/854": "Forest Department Sarawak · Hornbills",
	"https://iucnhornbills.org/rhinoceros-hornbill/": "IUCN Hornbill Specialist Group · Rhinoceros Hornbill species profile",
}
var catalog: EducationCatalog
var initial_page := ""
var _pages: Array[String] = []
var _body: VBoxContainer

func _ready() -> void:
	StoryUI.header(self, "Field guide", back)
	_body = StoryUI.scroll_column(self)
	_open(initial_page if not initial_page.is_empty() else "FAQ")

func _open(id: String) -> void:
	_pages.append(id)
	_render(id)

func back() -> void:
	_pages.pop_back()
	if _pages.is_empty():
		closed.emit()
	else:
		_render(_pages.back())

func _render(id: String) -> void:
	EducationUI.clear(_body)
	(_body.get_parent() as ScrollContainer).scroll_vertical = 0
	if id == "FAQ":
		_body.add_child(StoryUI.label("Frequently asked questions", 28))
		for topic: String in TOPICS:
			_link(topic, topic)
		_link("References", "References")
	elif id == "References":
		_show_references()
	elif id == CREDITS:
		_body.add_child(StoryUI.label(CREDITS, 28))
		_body.add_child(StoryUI.label("Game design and storyboard · Group SimSimi", 22))
		_body.add_child(StoryUI.label("The Scout cutout and restoration trees use original project artwork. The garden clearing is a project-directed generated illustration. Music and interface sounds are synthesized locally.", 20))
		_body.add_child(StoryUI.label("Godot Engine", 24, StoryUI.AMBER))
		_body.add_child(StoryUI.label(Engine.get_license_text(), 18))
		_body.add_child(StoryUI.label("Engine and third-party notices: https://godotengine.org/license/", 18))
	elif id == CONTROLS:
		_body.add_child(StoryUI.label(CONTROLS, 28))
		_body.add_child(StoryUI.label(TOPICS[DEPLOY_TOPIC], 22))
		_body.add_child(StoryUI.label(TOPICS[ESCAPE_TOPIC], 22))
		_body.add_child(StoryUI.label("Resume continues the same operation. Use 1× or 2× to change combat speed.", 22))
	elif TOPICS.has(id):
		_body.add_child(StoryUI.label(id, 26))
		_body.add_child(StoryUI.label(TOPICS[id], 22))
	elif catalog.facts.has(id):
		var fact: Dictionary = catalog.facts[id]
		var article := StoryUI.panel(_body, true)
		var frame := StyleBoxTexture.new()
		frame.texture = ARTICLE_FRAME
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var vertical: bool = side in [SIDE_TOP, SIDE_BOTTOM]
			frame.set_texture_margin(side, 59.0 if vertical else 44.0)
			frame.set_content_margin(side, 67.0 if vertical else 50.0)
		article.get_parent().add_theme_stylebox_override("panel", frame)
		article.add_child(StoryUI.label(fact.title, 26, StoryUI.INK))
		article.add_child(StoryUI.label(fact.text, 22, StoryUI.INK))
		EducationUI.credit_sources(article, catalog, fact.source_ids, StoryUI.INK)

func _show_references() -> void:
	_body.add_child(StoryUI.label("Offline references", 28))
	_link(CREDITS, CREDITS)
	for url: String in REFERENCES:
		_body.add_child(StoryUI.label(REFERENCES[url], 22, StoryUI.AMBER))
		_body.add_child(StoryUI.label(url, 18, StoryUI.BEIGE))
	_body.add_child(StoryUI.label("Group SimSimi · Kenyalang Rangers Game Design Document v1.0", 22, StoryUI.AMBER))
	_body.add_child(StoryUI.label("Battle and deployment, pp. 8–9. Headquarters and side activities, pp. 19–27. Offline saves and accessibility, pp. 28–30.", 20))
	_body.add_child(StoryUI.label("Visual layout reference · Yostar's official Arknights listing", 22, StoryUI.AMBER))
	_body.add_child(StoryUI.label("https://play.google.com/store/apps/details?id=com.YoStarEN.Arknights", 18, StoryUI.BEIGE))
	var other_sources := catalog.sources.keys().filter(func(id: String) -> bool: return not REFERENCES.has(catalog.sources[id].url))
	EducationUI.credit_sources(_body, catalog, other_sources, StoryUI.CREAM)
	if catalog.facts.is_empty():
		_body.add_child(StoryUI.label("Conservation articles await review.", 20))
		return
	_body.add_child(StoryUI.label("Conservation articles", 22, StoryUI.AMBER))
	for fact_id: String in catalog.facts:
		_link(catalog.facts[fact_id].title, fact_id)

func _link(caption: String, id: String) -> void:
	var button := StoryUI.action(caption)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_open.bind(id))
	_body.add_child(button)
