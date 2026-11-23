class_name FieldGuide
extends VBoxContainer

signal closed

const TOPICS := {
	"How do I deploy and retreat?": "Drag a card to a highlighted tile. For a melee Ranger, release on the left or right half to lock facing. Tap a Ranger to use or arm a skill. Choose a tile and confirm targeted skills. Hold a Ranger to reveal Retreat.",
	"What happens when enemies escape?": "Combat enemies that reach the tree-veiled tunnel reduce Operational Integrity. At zero Integrity the operation ends in defeat. Pause to inspect the waves and active enemies.",
	"Where do I earn and spend Funds?": "Claim stored Funds in Finance. Operations and side activities can pay Funds. Use them for Headquarters rooms and deployable upgrades. Logistic Tokens pay for deployment during a battle.",
	"How does the garden grow offline?": "Build Ecology to open two plots. Water halfway through the in-game growth time. Collect the mature tree to free the plot. The tree stays in the garden.",
	"How do I change sound or text?": "Open Settings from the Main Menu. Adjust Master, Music, Sound effects or Text size. Your choices persist on this device.",
}
var catalog: EducationCatalog
var initial_fact := ""
var _pages: Array[String] = []
var _body: VBoxContainer

func _ready() -> void:
	StoryUI.header(self, "Field guide", back)
	_body = StoryUI.scroll_column(self)
	_open(initial_fact if not initial_fact.is_empty() else "FAQ")

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
		_body.add_child(StoryUI.label("Offline references", 28))
		_body.add_child(StoryUI.label("Kenyalang Rangers · Game Design Document v1.0", 22, StoryUI.AMBER))
		_body.add_child(StoryUI.label("Battle and deployment, pp. 8–9. Headquarters and side activities, pp. 19–27. Offline saves and accessibility, pp. 28–30.", 20))
		_body.add_child(StoryUI.label("Conservation sources", 22, StoryUI.AMBER))
		for fact_id: String in catalog.facts:
			_link(catalog.facts[fact_id].title, fact_id)
		if catalog.sources.is_empty():
			_body.add_child(StoryUI.label("Conservation references await content approval.", 20))
		EducationUI.credit_sources(_body, catalog, catalog.sources.keys(), StoryUI.CREAM)
	elif TOPICS.has(id):
		_body.add_child(StoryUI.label(id, 26))
		_body.add_child(StoryUI.label(TOPICS[id], 22))
	elif catalog.facts.has(id):
		var fact: Dictionary = catalog.facts[id]
		_body.add_child(StoryUI.label(fact.title, 26))
		_body.add_child(StoryUI.label(fact.text, 22))
		EducationUI.credit_sources(_body, catalog, fact.source_ids, StoryUI.BEIGE)

func _link(caption: String, id: String) -> void:
	var button := StoryUI.action(caption)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_open.bind(id))
	_body.add_child(button)
