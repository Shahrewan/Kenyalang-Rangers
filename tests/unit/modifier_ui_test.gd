extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
var _path := "user://c16-modifiers-%d.json" % OS.get_process_id()
var _checks := 0
var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	var data := CampaignSave.fresh()
	data.leader_name = "C16 fixture"
	data.rooms[String(HeadquartersCatalog.CONTROL)] = 4
	data.rooms[String(HeadquartersCatalog.HR)] = 2
	data.rooms[String(HeadquartersCatalog.MECHANICAL)] = 2
	data.rooms["room.r_d_eco"] = 4
	data.rooms["room.r_d_combat"] = 2
	data.rooms["room.r_d_crisis"] = 5
	for id in ["C1-01", "C1-02", "C1-03", "C1-04", "C1-05", "C2-01", "C2-02", "C2-03", "C2-04", "C2-05", "C2-06"]:
		data.records[id] = {"cleared": true, "perfect": false}
	for id in ["ranger.guard_veteran", "ranger.combat_medic", "facility.medic_cabin", "facility.sonic_turret"]:
		data.owned.append(id)
	ProfileFile.replace(_path, data, false)
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	await process_frame
	await _story(app)
	await _trial(app)
	app.free()
	await process_frame
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("Modifier UI: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _story(app: Control) -> void:
	app._screen.get_node("%OpenCampaign").pressed.emit()
	_button(app, "Operation_C1_01").pressed.emit()
	_check("Thin Supply Line" in _labels(app._screen), "Story planning shows the authored fixed debuff")
	_button(app, "OpenModifiers").pressed.emit()
	await process_frame
	_check(app._screen is ModifierPicker and app._screen.find_children("Modifier_B*", "CheckBox", true, false).size() == 15 and _button(app, "ShowDebuffs") == null, "Story picker shows every buff and leaves the fixed debuff read-only")
	_check(_button(app, "Modifier_B02").disabled and "Heat-enabled" in _labels(app._screen), "Unlocked Heat buff is visibly ineligible on T01")
	_check(_button(app, "Modifier_B06").disabled and "R&D Combat Lv.3" in _labels(app._screen), "Unresearched buff shows its exact required room tier")
	_toggle(app, "B01", true)
	_check(_button(app, "Modifier_B01").button_pressed and _button(app, "Modifier_B05").disabled, "Chapter 1 picker enforces a single selection")
	app._go_back()
	_check(app._screen.plan.modifier_selected(&"B01") and not _button(app, "StartOperation").disabled, "Returning from the picker keeps the selected effect and legal opening")
	_button(app, "StartOperation").pressed.emit()
	var field := app._screen as CampaignBattle
	field.set_physics_process(false)
	_check(field.battle.clock.dialogue_open and field.battle.effects.ids == [&"D01", &"B01"], "Campaign starts with the exact resolved modifiers held for dialogue")
	field.get_node("%Skip").pressed.emit()
	for i in 301:
		field.battle.clock.advance_frame()
	field._refresh()
	_check(field.get_node("%ReconNotice").visible and "5 s" in field.get_node("%ReconNotice").text and field.battle.active.is_empty(), "The field HUD shows recon before the first spawn")
	field.battle.clock.paused = true
	field._abandon()
	app.show_story()
	_button(app, "Operation_C2_07").pressed.emit()
	_button(app, "OpenModifiers").pressed.emit()
	_check(not _button(app, "Modifier_B02").disabled, "The same unlocked Heat buff is eligible on a Heat stage")
	_toggle(app, "B01", true)
	_toggle(app, "B02", true)
	_check(_button(app, "Modifier_B03").disabled and "2 / 2 distinct buffs" in _labels(app._screen), "Chapter 2 allows two distinct buffs")
	app._go_back()
	var result: ModifierResolution = app._screen.plan.resolved()
	_check(result.can_start() and result.stage.modifier_ids == [&"D14", &"D06", &"B01", &"B02"] and is_equal_approx(result.stage.heat_gain_scale, 1.05), "Chapter 2 preview uses both fixed debuffs and both selected buffs")

func _trial(app: Control) -> void:
	app.show_menu()
	_button(app, "OpenChaos").pressed.emit()
	_button(app, "OpenModifierTrial").pressed.emit()
	_button(app, "OpenModifiers").pressed.emit()
	await process_frame
	_button(app, "ShowDebuffs").pressed.emit()
	_check(app._screen.find_children("Modifier_D*", "CheckBox", true, false).size() == 15, "Chaos trial exposes all optional debuffs")
	_toggle(app, "D05", true)
	_check(_button(app, "Modifier_D01").disabled and "generating Post" in _labels(app._screen), "D05 visibly disables an effect relying on the removed Post")
	_button(app, "ShowBuffs").pressed.emit()
	_check(_button(app, "Modifier_B13").disabled and "cannot be combined" in _labels(app._screen), "D05 disables the otherwise unlocked Requisition")
	app._go_back()
	var plan: OperationPlan = app._screen.plan
	var result := plan.resolved()
	_check("Opening · 120 Tokens" in _labels(app._screen) and result.facility_slots == plan.selected_count(false) - 1 and result.modifier_points() == 200, "Trial preview reports stockpile, effective slots and eligible points")
	for spec in plan.choices:
		if not spec.logistics_post:
			var id := "Equip_" + String(spec.id).replace(".", "_")
			_button(app, id).button_pressed = false
	_check(_button(app, "StartOperation").disabled and plan.resolved().score_entries.is_empty(), "Changing loadout invalidates an unaffordable stockpile and clears its score")
	for spec in plan.choices:
		if not spec.logistics_post:
			var id := "Equip_" + String(spec.id).replace(".", "_")
			_button(app, id).button_pressed = true
	_button(app, "StartOperation").pressed.emit()
	var field := app._screen as BattleScene
	field.set_physics_process(false)
	_check(field.battle.deployment.tokens == 120 and field.battle.deployment.rules.fixed_stockpile and plan.deployment_entries().all(func(spec: DeploymentSpec) -> bool: return not spec.logistics_post), "Live trial shares the effective Post-free stockpile")
	field.get_node("%BackToMenu").pressed.emit()
	_button(app, "OpenModifiers").pressed.emit()
	_button(app, "ShowDebuffs").pressed.emit()
	_toggle(app, "D05", false)
	_toggle(app, "D14", true)
	_button(app, "ShowBuffs").pressed.emit()
	for id in ["B01", "B13", "B15"]:
		_toggle(app, id, true)
	app._go_back()
	_check(plan.modifier_count(true) == 3 and plan.resolved().modifier_points() == -300, "Chaos supports more than two distinct compatible buffs with signed contributions")
	_button(app, "StartOperation").pressed.emit()
	field = app._screen as BattleScene
	field.set_physics_process(false)
	_check(field.battle.deployment.tokens == 35 and field.battle.deployment.rules.yield_percent == 90 and field.battle.effects.amount(&"disable_skills") == 1, "Second trial consumes Requisition and Silent Mobilization together")
	_check(app._campaign_progress.snapshot().chaos.personal_best == 0 and app._campaign_progress.funds() == CampaignSave.STARTING_FUNDS, "Modifier trial leaves the persistent wallet and Chaos records intact")

func _button(app: Control, id: String) -> BaseButton:
	return app._screen.find_child(id, true, false)

func _toggle(app: Control, id: String, enabled: bool) -> void:
	var check := _button(app, "Modifier_" + id)
	_check(check != null and not check.disabled, "%s is available for its attempted UI action" % id)
	if check != null and not check.disabled:
		check.button_pressed = enabled

func _labels(page: Control) -> String:
	var parts := PackedStringArray()
	for label: Label in page.find_children("*", "Label", true, false):
		parts.append(label.text)
	return "\n".join(parts)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
