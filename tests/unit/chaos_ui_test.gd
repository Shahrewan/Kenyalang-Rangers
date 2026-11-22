extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
var _path := "user://c17-chaos-ui-%d.json" % OS.get_process_id()
var _checks := 0
var _failed := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(960, 540)
	var profile := CampaignSave.fresh()
	profile.leader_name = "Chaos QA"
	profile.rooms["room.mechanical"] = 1
	profile.rooms["room.r_d_combat"] = 2
	profile.owned.append_array(["ranger.combat_medic", "facility.sonic_turret"])
	ProfileFile.replace(_path, profile, false)
	var app := LAUNCHER.instantiate()
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	await process_frame
	_press(app, "OpenChaos")
	_check(app._screen is ChaosRoutePage and app._screen.find_children("Route_T*", "Button", true, false).size() == 6, "Main Menu exposes all six original routes")
	_check(_label(app, "ChaosPersonalBest") == "Personal best · 0" and app._screen.find_child("TrophyTier0", true, false) != null, "Route page displays the shared empty trophy")
	_press(app, "Route_T05")
	_check(app._chaos_configuration.route_id == &"T05", "The route button selects Imbak Canyon")
	_press(app, "Route_T02")
	_press(app, "ConfigureChaos")
	_check(app._screen is ChaosComposer and app._screen.find_children("WaveSlot*", "Button", true, false).size() == 5, "Composer creates five independent wave tabs")
	_check(_button(app, "StartChaos").disabled and "at least one enemy" in _label(app, "ChaosFeedback"), "All-empty setup disables Start with guidance")
	_quantity(app, "E01", 49)
	_press(app, "Increase_E02")
	_check(_button(app, "Increase_E02").disabled and _button(app, "Increase_E03").disabled, "Plus controls stop at the mixed wave cap")
	_quantity(app, "E03", 50)
	_check(_label(app, "Count_E02") == "1" and _label(app, "Count_E03") == "0" and "50 / 50" in _button(app, "WaveSlot1").text, "The slider cannot add a 51st enemy")
	_press(app, "WaveSlot5")
	_press(app, "Increase_E01")
	_check(_label(app, "Count_E01") == "1", "The fifth slot has its own controls")
	_press(app, "Decrease_E01")
	_press(app, "WaveSlot1")
	_quantity(app, "E01", 0)
	_quantity(app, "E02", 20)
	for id in ["E03", "E04", "E08"]:
		_quantity(app, id, 10)
	_press(app, "WaveSlot2")
	_quantity(app, "E11", 10)
	_check(_label(app, "MedalScore") == "1,050", "Both wave totals and five occupied slots produce the live baseline score")

	_press(app, "EditLoadout")
	_check(_button(app, "Equip_ranger_combat_medic").button_pressed and _button(app, "Equip_facility_sonic_turret").button_pressed, "Loadout shows the real HQ-owned choices beside the score")
	_button(app, "Equip_ranger_combat_medic").button_pressed = false
	_check(_label(app, "MedalScore") == "1,150", "Opening one filled slot adds back only its 100-point deduction")
	_button(app, "Equip_ranger_combat_medic").button_pressed = true
	_press(app, "OpenModifiers")
	_toggle(app, "B05", true)
	_check("950 Medal Score" in _label(app, "ModifierSummary"), "The modifier sheet previews the complete score live")
	_press(app, "BackFromModifiers")
	_check(_label(app, "MedalScore") == "1,050" and not app._chaos_plan.modifier_selected(&"B05"), "Cancel restores the previous selection")
	_press(app, "OpenModifiers")
	_toggle(app, "B05", true)
	_press(app, "ShowDebuffs")
	_check(_button(app, "Modifier_D14").disabled, "Non-Heat Mulu visibly blocks Heat Surge")
	for id in ["D02", "D09", "D11"]:
		_toggle(app, id, true)
	_press(app, "ApplyModifiers")
	_check(_label(app, "MedalScore") == "1,350" and "54,000 Funds" in _label(app, "ChaosPayout") and _label(app, "ProjectedTrophy").ends_with("1"), "Composer displays the exact worked score, payout and projected Trophy Tier 1")
	_check("High-Impact Siege  +200" in _label(app, "ScoreBreakdown") and "3 Ranger / 2 Facility slots  −500" in _label(app, "ScoreBreakdown"), "The score breakdown shows individual effects and effective loadout deductions")
	_press(app, "EditWaves")
	_check((app._screen as ChaosComposer).wave_editor.slot == 1, "Returning to the editor preserves the chosen slot")
	_quantity(app, "E11", 0)
	_check(_button(app, "StartChaos").disabled and _label(app, "MedalScore") == "—" and "Siege" in _label(app, "ChaosFeedback"), "Changing the wave invalidates a selected debuff and blocks Start and payout")
	_quantity(app, "E11", 10)

	_press(app, "StartChaos")
	var field := app._screen as ChaosBattle
	field.set_physics_process(false)
	_check(field.stage.stage_id == &"T02" and field.battle.wave_count == 2 and field.run.score.configured_enemies == 60, "Start launches the exact two populated waves on the selected board")
	_check(not field.get_node("%Controls").visible and field.get_node("%DefeatedCount").text == "Defeated 0/60", "The real HUD uses configured enemies and hides preview controls")
	_press(app, "Pause")
	_check(field.get_node("%PauseOverlay").visible and field.battle.clock.paused, "Pause opens the shared inspection view")
	app.free()
	await process_frame
	app = LAUNCHER.instantiate()
	app.campaign_save_path = _path
	root.add_child(app)
	app.set_process(false)
	await process_frame
	_check(app._screen is ChaosComposer and "Challenge interrupted" in _label(app, "ChaosFeedback"), "Relaunch after interruption opens the configuration")
	_check(_label(app, "MedalScore") == "1,350" and app._chaos_configuration.route_id == &"T02" and app._campaign_progress.funds() == 10000, "Relaunch restores the exact route, waves, loadout and modifiers")
	_press(app, "WaveSlot2")
	_press(app, "StartChaos")
	field = app._screen as ChaosBattle
	field.set_physics_process(false)
	_check(field.battle.integrity == 100 and field.battle.clock.tick == 0 and field.battle.configured_defeated == 0, "Starting again after a cold relaunch uses fresh battle state")
	DirAccess.make_dir_absolute(_path + ".tmp")
	_play(field)
	await process_frame
	_check(app._screen is ChaosResultsPage and _button(app, "RetryChaosSave") != null and app._campaign_progress.funds() == 10000, "A failed result write exposes Retry without paying")
	DirAccess.remove_absolute(_path + ".tmp")
	_press(app, "RetryChaosSave")
	_check(_label(app, "ChaosResultTitle") == "Qualifying clear" and _label(app, "ChaosCreditedFunds") == "54,000 Funds credited", "Retry shows the live qualifying result and exact payout")
	_check(_label(app, "ChaosPersonalBest") == "Personal best · 1,350" and app._campaign_progress.owns(&"facility.skill_relay_station"), "The live result unlocks the first Facility and trophy")

	_press(app, "ReviewChaos")
	_check(_label(app, "MedalScore") == "1,350" and (app._screen as ChaosComposer).wave_editor.slot == 1, "Review preserves route, waves, modifiers and loadout")
	_press(app, "StartChaos")
	field = app._screen as ChaosBattle
	field.set_physics_process(false)
	_play(field, true)
	await process_frame
	_check(_label(app, "ChaosResultTitle") == "Escape · No payout" and _label(app, "ChaosCreditedFunds") == "0 Funds credited" and app._campaign_progress.funds() == 64000, "Surviving with one escape produces the unqualified report and no reward")

	_press(app, "ReviewChaos")
	_press(app, "StartChaos")
	field = app._screen as ChaosBattle
	field.set_physics_process(false)
	_press(app, "Pause")
	_press(app, "AskAbandon")
	_press(app, "ConfirmAbandon")
	_check(app._screen is ChaosComposer and app._campaign_progress.chaos_personal_best() == 1350 and _label(app, "MedalScore") == "1,350", "Confirmed abandon returns to the same configuration without touching progress")
	_press(app, "EditLoadout")
	_check(_button(app, "Equip_facility_skill_relay_station") != null, "The earned Chaos Facility is available to equip on the next run")
	app.show_menu()
	app._screen.get_node("%OpenHeadquarters").pressed.emit()
	_check(_label(app, "ChaosPersonalBest") == "Personal best · 1,350" and app._screen.find_child("TrophyTier1", true, false) != null, "The ground-floor HQ displays the same record and trophy")
	_press(app, "HeadquartersChaos")
	_check(app._screen is ChaosRoutePage and _label(app, "ChaosPersonalBest") == "Personal best · 1,350", "The HQ entrance opens the same Chaos trophy and routes")
	app._go_back()
	_check(app._screen is HeadquartersOverview, "Back returns to the originating HQ")
	var restored := CampaignProgress.new(_path)
	_check(restored.chaos_personal_best() == 1350 and restored.funds() == 64000 and restored.owns(&"facility.skill_relay_station"), "Cold reload preserves the reciprocal record, payout and unlock")
	app.free()
	await process_frame
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_path + suffix):
			DirAccess.remove_absolute(_path + suffix)
	print("Chaos UI: %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)

func _play(field: ChaosBattle, escape_first := false) -> void:
	var battle := field.battle
	for iteration in 14000:
		if battle.outcome != BattleSimulation.Outcome.RUNNING:
			break
		battle.clock.advance_frame()
		for id: int in battle.active.keys():
			if id == 1 and escape_first:
				var enemy := battle.active[id]
				enemy.distance = enemy.route.cells.size() - 1.00001
			else:
				battle.defeat_enemy(id)
	field._refresh()

func _button(app: Control, id: String) -> BaseButton:
	return app._screen.find_child(id, true, false)

func _press(app: Control, id: String) -> void:
	_button(app, id).pressed.emit()

func _quantity(app: Control, id: String, count: int) -> void:
	var slider := app._screen.find_child("Quantity_" + id, true, false) as HSlider
	slider.value = count

func _toggle(app: Control, id: String, enabled: bool) -> void:
	var button := _button(app, "Modifier_" + id)
	_check(not button.disabled, "%s is eligible before toggling" % id)
	button.button_pressed = enabled

func _label(app: Control, id: String) -> String:
	var label := app._screen.find_child(id, true, false) as Label
	return label.text if label != null else ""

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("FAIL ", message)
