class_name OnboardingGuide
extends VBoxContainer

signal step_changed
signal room_requested(id: StringName)

const MISSIONS := {
	&"C1-01": [
		["Your first three placements", "Tap the Logistics Post card marked Free, then tap the left of the two marked raised tiles. The Post earns Tokens every 10 combat seconds. Then place Scout Sniper on the marked raised tile and Patrolman on the marked path tile."],
		["Tap or drag to place", "Tap a card and tap a highlighted tile, or drag a card up onto the field. Swipe straight across the tray to see more cards. When placing Patrolman, tap Face left, then Deploy. Enemies enter from the left."],
		["How a battle is won", "Rangers attack automatically. Patrolman holds ground enemies in place so Scout can shoot them. A unit’s HP bar shows how much health is left. Keep enemies away from the wooded tunnel on the right."],
		["Read the top bar", "Wave counts groups of enemies. Integrity starts at 100 and falls when enemies escape. At zero, you lose. Finish with no escapes for a perfect clear. Pause opens Enemy Intel. Stay at 1× while learning."],
	],
	&"C1-02": [
		["Bring your own supply", "Open Headquarters → Mechanical if it is unbuilt. Build it with Funds, return to this plan, and check Logistics Post under Facilities. Keep Patrolman and Scout Sniper selected. A normal opening starts with zero Tokens."],
		["Spend Tokens in battle", "The first equipped Logistics Post is free and works immediately. Most Facilities need two raised tiles side by side. Later Posts and other Facilities cost Tokens and take time to build. Hold an unfinished Facility for Cancel build to refund its paid Tokens."],
		["Build a firing line", "Place Patrolman on the path facing incoming enemies. His forward tiles are his attack range. Scout covers a square around a raised tile. Overlap their coverage. Blocks are limited, so extra enemies can walk past a busy Ranger."],
		["Read this operation", "This mission’s fixed effect speeds up the enemy. Pause to read the enemy names, HP, routes and counterplay. An escape lowers Integrity. You can still clear a regular operation with positive Integrity after all waves resolve."],
	],
	&"C1-03": [
		["Bring Combat Medic", "Equip Combat Medic with a blocker, a damage dealer, and Logistics Post. Put the Medic on a raised tile beside the path. Compare its highlighted square with the position of the ally you want to heal."],
		["Use skills deliberately", "Check the small skill orb near the unit. A ready mark means a charge can be used. Quick tap an immediate skill. For a targeted skill such as Emergency Treatment, quick tap the Medic, tap an eligible hurt ally’s tile, and choose Confirm skill."],
		["Read charge and cooldown", "Some skills recharge; others have limited uses. A locked orb may mean a Records requirement or an effect blocking skills. Scout’s Focus requires its Records enhancement. A card cooldown controls placement, separately from the unit’s skill."],
		["Retreat and place again", "Hold a Ranger until Retreat appears, then tap Retreat. You release its tile and can use the same card again once its cooldown ends and you can pay. A second copy may also be placed on free tiles once the type cooldown ends."],
		["Watch the entrance", "Contraband Runners close gaps quickly. Put blockers in front of your ranged coverage. A messenger can appear in the story without being a combat enemy."],
	],
	&"C1-04": [
		["Open the next operation", "If Watch the Ridge is locked after Narrow Escape, upgrade Headquarters → Control Room to Level 2. Room gates and previous clears are both shown in Story."],
		["Combine the roles", "Put a blocker on the route, aim toward the approach, and overlap elevated damage and healing. A two-cell Ranger needs two connected ground tiles. While choosing a side, the arrow and highlighted tiles show where the Ranger can attack."],
		["Read the enemy before it arrives", "Rifle Spotters shoot Rangers from range. Give exposed Rangers healing or move the line. Shield Carriers have a large HP pool, so overlap damage. Pause to check the wave list and nearby threats."],
		["Plan around the rules", "Fixed effects apply to this mission. R&D rooms unlock optional buffs. Read the effect and any eligibility requirement in Edit modifiers. Use wave breaks to check HP, remaining Tokens, skill charges and the next entry."],
	],
	&"C1-05": [
		["Use the fixed stockpile", "You start with 120 Logistic Tokens under Fixed Stockpile, which disables Logistics Posts. Start with a blocker and overlapping ranged damage. Keep some Tokens for support and replacements."],
		["Keep a line through the waves", "Give your blocker room and healing. Watch HP and skill charges. Use Pause to inspect the incoming enemies, and use 1× when you want time to read the board. Retreat only when you have a plan for the tile it opens."],
		["Capture the Captain", "Keep the Diversion Captain away from the tunnel. The Captain speeds nearby enemies and can call Poacher reinforcements. Stay ready for both its entry and the extra enemies. A Captain escape ends this operation immediately."],
		["Prepare for regional operations", "Enemy Intel explains the next region’s threats. Aerial enemies fly past ground blocks and need anti-air coverage. Concealed enemies need detection. Siege can damage Facilities, even during construction. Technology and Heat have their own counters; check the mission briefing and tags."],
	],
}
const HEADQUARTERS := [
	["1 · Build Mechanical first", "Tap Open Mechanical below. Choose Build room, then confirm the Funds cost. Mechanical lets you equip a Logistics Post for Hold the Line. The Starter Post from First Contact was only for that mission.", "room.mechanical", "Open Mechanical"],
	["2 · Open the next Story region", "Control Room levels reveal more Story operations. Open Control Room to see the exact cost and any gate. Each mission still requires the preceding clear.", "room.control_room", "Open Control Room"],
	["3 · Equip and improve your teams", "Human Resources manages Ranger slots and permanent Ranger upgrades. Mechanical manages Facility slots and upgrades. Open a unit card, select a target level, compare the stats, then confirm only if the cost fits.", "room.human_resources", "Open Human Resources"],
	["4 · Earn and spend Funds", "Mission rewards, Finance and activities add Funds to your persistent wallet. Claim stored Funds in Finance. Logistic Tokens are for battle placements and start fresh each operation.", "room.finance_room", "Open Finance"],
	["5 · Explore the other rooms", "R&D Eco, Combat, Guard and Crisis unlock different optional battle buffs. Ecology opens Reforestation. Outreach pays for responses, and Records quizzes unlock selected Ranger enhancements. Check each room before committing Funds.", "room.records", "Open Records"],
]

var pages: Array
var _index := 0
var _heading: Label
var _body: Label
var _pages_label: Label
var _prev: Button
var _next: Button
var _open: Button

func _ready() -> void:
	var card := StoryUI.panel(self)
	_heading = StoryUI.label("", 23, StoryUI.AMBER)
	card.add_child(_heading)
	_body = StoryUI.label("", 20)
	card.add_child(_body)
	if pages[0].size() > 2:
		_open = _button(card, "", "LessonOpenRoom", _open_room, true)
	var row := StoryUI.row(card, 8)
	_prev = _button(row, "Previous", "LessonPrevious", _move.bind(-1))
	_pages_label = StoryUI.label("", 17, StoryUI.BEIGE)
	_pages_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_pages_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pages_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_pages_label)
	_next = _button(row, "Next step", "LessonNext", _move.bind(1))
	_render()

func _button(row: Container, caption: String, id: String, callback: Callable, primary := false) -> Button:
	var button := StoryUI.action(caption, primary)
	button.name = id
	button.custom_minimum_size.y = 64
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	row.add_child(button)
	return button

func _move(by: int) -> void:
	var previous := _index
	_index = clampi(_index + by, 0, pages.size() - 1)
	_render()
	if _index != previous:
		step_changed.emit()

func _render() -> void:
	var topic: Array = pages[_index]
	_heading.text = topic[0]
	_body.text = topic[1]
	_pages_label.text = "%d / %d" % [_index + 1, pages.size()]
	_prev.disabled = _index == 0
	_next.disabled = _index == pages.size() - 1
	if _open != null:
		_open.text = topic[3]

func _open_room() -> void:
	room_requested.emit(StringName(pages[_index][2]))
