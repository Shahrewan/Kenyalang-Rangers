class_name HeadquartersRoomPage
extends VBoxContainer

signal back_requested
signal activity_requested(room: HeadquartersRoom)

const UNLOCK_LABELS := {
	"records_chapter.scout_sniper": "Scout Sniper · Steady Aim",
	"records_chapter.patrolman": "Patrolman · Reinforced Patrol",
	"records_chapter.combat_medic": "Combat Medic · Emergency Treatment",
	"records_chapter.woods_tracker": "Woods Tracker",
}

var progress: CampaignProgress
var definition: HeadquartersRoom
var _balance: Label
var _status: Label
var _benefits: Label
var _storage: Label
var _next: Label
var _requirement: Label
var _notice: Label
var _purchase: Button
var _activity: Button
var _claim: Button
var _art: HeadquartersOfficeArt
var _dialog: ConfirmationDialog
var _confirmed: Callable
var _displayed_storage := -1

func _ready() -> void:
	theme = HeadquartersArt.THEME
	add_theme_constant_override("separation", 12)
	var back := StoryUI.header(self, definition.label, func() -> void: back_requested.emit(), "Funds")
	back.custom_minimum_size.y = 64
	_balance = back.get_parent().get_node("FundsSummary")
	var body := StoryUI.row(self, 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_scroll := StoryUI.scroll_column(body)
	(detail_scroll.get_parent() as Control).size_flags_stretch_ratio = 1.45
	var details := StoryUI.panel(detail_scroll, true)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	_status = StoryUI.label("", 28, StoryUI.INK)
	details.add_child(_status)
	_art = HeadquartersOfficeArt.new()
	_art.catalog = HeadquartersArt.new()
	_art.room_id = definition.id
	_art.level = progress.room_level(definition.id)
	_art.custom_minimum_size.y = 184
	details.add_child(_art)
	_benefits = StoryUI.label("", 20, StoryUI.INK)
	details.add_child(_benefits)
	if definition.role == HeadquartersRoom.Role.FINANCE:
		_storage = StoryUI.label("", 21, StoryUI.INK)
		details.add_child(_storage)
		_claim = StoryUI.action("Claim stored Funds")
		_claim.name = "ClaimFinance"
		_claim.pressed.connect(_request_claim)
		actions.add_child(_claim)
	else:
		var activity := _activity_title()
		if not activity.is_empty():
			_activity = StoryUI.action(activity)
			_activity.name = "RoomActivity"
			_activity.pressed.connect(func() -> void: activity_requested.emit(definition))
			actions.add_child(_activity)
	var purchase_panel := StoryUI.panel(StoryUI.scroll_column(body))
	_next = StoryUI.label("", 25, StoryUI.AMBER)
	purchase_panel.add_child(_next)
	_requirement = StoryUI.label("", 20)
	purchase_panel.add_child(_requirement)
	_purchase = StoryUI.action("", true)
	_purchase.name = "RoomPurchase"
	_purchase.pressed.connect(_confirm_room_purchase)
	actions.add_child(_purchase)
	for action: Button in actions.get_children():
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.custom_minimum_size.y = 76
		action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice = StoryUI.label("", 19, StoryUI.AMBER)
	add_child(_notice)
	add_child(actions)
	_dialog = HeadquartersArt.confirmation(self, "Confirm", "Confirm")
	_dialog.confirmed.connect(func() -> void: _confirmed.call())
	set_process(_storage != null)
	_refresh()

func _activity_title() -> String:
	match definition.role:
		HeadquartersRoom.Role.CONTROL:
			return "Open Story Mode"
		HeadquartersRoom.Role.HR:
			return "Ranger upgrades"
		HeadquartersRoom.Role.MECHANICAL:
			return "Facility upgrades"
		HeadquartersRoom.Role.ECOLOGY:
			return "Reforestation"
		HeadquartersRoom.Role.OUTREACH:
			return "Open Outreach"
		HeadquartersRoom.Role.RECORDS:
			return "Records Encyclopaedia"
	return ""

func _refresh() -> void:
	var level := progress.room_level(definition.id)
	_balance.text = "%s Funds" % StoryUI.funds(progress.funds())
	_status.text = "Unbuilt" if level == 0 else "Level %d of %d" % [level, HeadquartersCatalog.MAX_LEVEL]
	_art.update_level(level)
	_benefits.text = _benefits_at(level)
	if _activity != null:
		_activity.visible = level > 0
	var quote := progress.room_quote(definition.id)
	_purchase.visible = level < HeadquartersCatalog.MAX_LEVEL
	_purchase.disabled = not quote.error.is_empty()
	_purchase.text = "Build room" if level == 0 else "Upgrade room"
	if _purchase.visible:
		_next.text = "Level %d · %s Funds" % [quote.target, StoryUI.funds(quote.cost)]
		_requirement.text = _benefits_at(quote.target)
		if definition.gate != HeadquartersRoom.Gate.NONE and quote.target == definition.gate_level:
			var gate := "%d%% restoration" % definition.gate_minimum if definition.gate == HeadquartersRoom.Gate.RESTORATION else "%d Best or Acceptable responses" % definition.gate_minimum
			_requirement.text += "\nRequires " + gate + "."
		if quote.shortfall > 0:
			_requirement.text += "\nNeed %s more Funds." % StoryUI.funds(quote.shortfall)
	else:
		_next.text = "Maximum level"
		_requirement.text = ""
	_notice.visible = not _notice.text.is_empty()
	if _storage != null:
		_update_storage()

func _benefits_at(level: int) -> String:
	if level == 0:
		return "Build this room to activate its benefits."
	var unlocked := definition.unlocks(level)
	match definition.role:
		HeadquartersRoom.Role.CONTROL:
			return "Reveals %s. Each operation still requires its preceding clear." % ", ".join(unlocked)
		HeadquartersRoom.Role.HR:
			return "%d Ranger loadout slots" % definition.capacity(level)
		HeadquartersRoom.Role.MECHANICAL:
			return "%d Facility slots and ordinary Logistics Post access" % definition.capacity(level)
		HeadquartersRoom.Role.FINANCE:
			return "%d Funds per active second · %s storage cap" % [definition.income(level), StoryUI.funds(definition.storage(level))]
		HeadquartersRoom.Role.ECOLOGY:
			return "%d garden plots · %d%% restoration reached" % [definition.capacity(level), progress.restoration_percent()]
		HeadquartersRoom.Role.OUTREACH:
			return "Best  +%s\nAcceptable  +%s\nPoor  0\nHarmful  %s\n%d Best or Acceptable responses" % [
				StoryUI.funds(definition.outreach_change(level, &"best")), StoryUI.funds(definition.outreach_change(level, &"acceptable")),
				StoryUI.funds(definition.outreach_change(level, &"harmful")), progress.outreach_successes(),
			]
		HeadquartersRoom.Role.RECORDS:
			return "Facts archive" + _unlock_summary(unlocked)
		HeadquartersRoom.Role.RESEARCH:
			return "Research unlocks" + _unlock_summary(unlocked) if not unlocked.is_empty() else "Next tiers unlock planning effects."
	return ""

func _unlock_summary(ids: PackedStringArray) -> String:
	var labels := PackedStringArray()
	for id in ids:
		var label: String = UNLOCK_LABELS.get(id, id)
		var modifier := BattleModifiers.CATALOG.definition(StringName(id))
		labels.append("%s · %s" % [id, modifier.display_name] if modifier != null else label)
	return "" if labels.is_empty() else "\n" + "\n".join(labels)

func _process(_delta: float) -> void:
	_update_storage()

func _update_storage() -> void:
	var amount := progress.finance_stored()
	if _displayed_storage == amount:
		return
	_displayed_storage = amount
	_storage.text = "%s stored Funds" % StoryUI.funds(amount)
	_claim.disabled = amount == 0

func _confirm_room_purchase() -> void:
	var quote := progress.room_quote(definition.id)
	if not quote.error.is_empty():
		_notice.text = quote.error
		_notice.show()
		return
	var detail := "%s · Level %d\nCost %s Funds\nBalance after purchase %s Funds" % [
		definition.label, quote.target, StoryUI.funds(quote.cost), StoryUI.funds(quote.balance),
	]
	_ask("Confirm room purchase", detail, "Confirm purchase", func() -> void:
		var error := progress.purchase_room(definition.id)
		_notice.text = "Room is now Level %d." % quote.target if error.is_empty() else error
		_refresh()
	)

func _request_claim() -> void:
	var amount := progress.finance_stored()
	if amount == 0:
		return
	var preview := progress.finance_preview(amount)
	if preview.discarded == 0:
		_claim_funds(amount)
		return
	var detail := "Credit %s Funds. Discard %s Funds above the %s wallet cap." % [
		StoryUI.funds(preview.credited), StoryUI.funds(preview.discarded), StoryUI.funds(FundsWallet.CAP),
	]
	_ask("Confirm Finance claim", detail, "Claim Funds", func() -> void: _claim_funds(amount))

func _claim_funds(amount: int) -> void:
	var result := progress.finance_preview(amount)
	if progress.claim_finance(amount):
		_notice.text = "Credited %s Funds." % StoryUI.funds(result.credited)
		if result.discarded > 0:
			_notice.text += " Discarded %s above the wallet cap." % StoryUI.funds(result.discarded)
	else:
		_notice.text = "Could not save the claim. Check local storage."
	_refresh()

func _ask(title: String, detail: String, caption: String, action: Callable) -> void:
	_confirmed = action
	_dialog.title = title
	_dialog.dialog_text = "%s\n\n%s" % [title, detail]
	_dialog.ok_button_text = caption
	_dialog.popup_centered(Vector2i(590, 264))
	_dialog.get_cancel_button().grab_focus()
