class_name CampaignAccessPage
extends VBoxContainer

signal back_requested

var progress: CampaignProgress
var _balance: Label
var _finance: Label
var _control: Label
var _mechanical: Label
var _claim: Button
var _build: Button
var _upgrade: Button
var _feedback: Label
var _confirmation: ConfirmationDialog
var _confirmed_claim: Dictionary

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	StoryUI.header(self, "Campaign access", func() -> void: back_requested.emit())
	_balance = StoryUI.label("", 24, StoryUI.AMBER)
	add_child(_balance)
	var rooms := StoryUI.scroll_column(self)
	var finance := StoryUI.panel(rooms)
	_finance = StoryUI.label("", 22)
	finance.add_child(_finance)
	_claim = StoryUI.action("Claim stored Funds", true)
	_claim.pressed.connect(_request_claim)
	finance.add_child(_claim)
	var mechanical := StoryUI.panel(rooms)
	_mechanical = StoryUI.label("", 22)
	mechanical.add_child(_mechanical)
	_build = StoryUI.action("Build Mechanical · 20,000 Funds", true)
	_build.pressed.connect(func() -> void: _report(progress.build_mechanical(), "Mechanical Lv.1 built."))
	mechanical.add_child(_build)
	var control := StoryUI.panel(rooms)
	_control = StoryUI.label("", 22)
	control.add_child(_control)
	_upgrade = StoryUI.action("Upgrade Control", true)
	_upgrade.pressed.connect(func() -> void: _report(progress.upgrade_control(), "Control upgraded."))
	control.add_child(_upgrade)
	_feedback = StoryUI.label("", 19, StoryUI.AMBER)
	add_child(_feedback)
	_confirmation = ConfirmationDialog.new()
	_confirmation.title = "Claim Funds"
	_confirmation.confirmed.connect(func() -> void:
		var quoted: int = _confirmed_claim.credited + _confirmed_claim.discarded
		if progress.finance_preview(quoted) == _confirmed_claim:
			_claim_funds(quoted)
		else:
			_request_claim.call_deferred()
	)
	add_child(_confirmation)
	_update()

func _process(_delta: float) -> void:
	var preview := progress.finance_preview()
	var stored: int = preview.credited + preview.discarded
	var text := "Finance Lv.1 · %d / %d stored Funds" % [stored, CampaignProgress.FINANCE_CAP]
	if text != _finance.text:
		_finance.text = text
		_claim.disabled = stored == 0

func _update() -> void:
	var profile := progress.snapshot()
	_balance.text = "%d Funds" % profile.funds
	_mechanical.text = "Mechanical Lv.1 · 2 Facility slots" if profile.mechanical else "Mechanical · Unlocks 2 Facility slots and the ordinary Logistics Post"
	_build.visible = not profile.mechanical
	_build.disabled = profile.funds < CampaignProgress.MECHANICAL_COST
	_control.text = "Control Lv.%d · Reveals Story operations" % profile.control
	var price := progress.control_upgrade_cost()
	_upgrade.text = "Upgrade Control · %d Funds" % price
	_upgrade.visible = price > 0
	_upgrade.disabled = profile.funds < price
	_process(0.0)

func _request_claim() -> void:
	var preview := progress.finance_preview()
	if preview.discarded > 0:
		_confirmed_claim = preview
		_confirmation.dialog_text = "Credit %d Funds and discard %d Funds above the wallet cap?" % [preview.credited, preview.discarded]
		_confirmation.popup_centered()
	else:
		_claim_funds()

func _claim_funds(amount := -1) -> void:
	var preview := progress.finance_preview(amount)
	_report(progress.claim_finance(amount), "Claimed %d Funds. Discarded %d above the cap." % [preview.credited, preview.discarded] if preview.discarded > 0 else "Claimed %d Funds." % preview.credited)

func _report(saved: bool, message: String) -> void:
	_feedback.text = message if saved else "Could not save the change. Check local storage."
	_update()
