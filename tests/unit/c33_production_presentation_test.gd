extends SceneTree

const LAUNCHER := preload("res://scenes/menus/launcher.tscn")
const PATROL := &"ranger.patrolman"
const POST := &"facility.logistics_post"

var _save := "user://c33-presentation-%d.json" % OS.get_process_id()
var _output := ""
var _app: Control
var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(960, 540)
	if args.size() == 3 and DisplayServer.get_name() != "headless":
		_output = args[0]
		var dims := args[1].split("x")
		root.size = Vector2i(int(dims[0]), int(dims[1]))
		DirAccess.make_dir_recursive_absolute(_output)

	var profile := CampaignSave.fresh()
	profile.leader_name = "Rimba"
	for room in [HeadquartersCatalog.HR, HeadquartersCatalog.MECHANICAL, HeadquartersCatalog.OUTREACH, HeadquartersCatalog.RECORDS, HeadquartersCatalog.ECOLOGY]:
		profile.rooms[String(room)] = 2
	profile.rooms["room.r_d_combat"] = 2
	profile.owned.append_array(["ranger.combat_medic", "facility.sonic_turret"])
	_check(ProfileFile.replace(_save, profile, false), "Seed a disposable presentation profile")
	_app = LAUNCHER.instantiate()
	_app.campaign_save_path = _save
	root.add_child(_app)
	_app.set_process(false)
	if not _output.is_empty():
		_app.presentation.values.text = int(args[2])
		_app._restyle()

	await _capture("main-menu")
	_press("OpenChaos")
	await _check_routes()
	await _check_chaos_results()
	await _check_boss()
	await _visit_other_screens()
	_app.free()
	await process_frame
	for stem in [_save, _save + ".settings"]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(stem + suffix):
				DirAccess.remove_absolute(stem + suffix)
	print("C33 production presentation: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check_routes() -> void:
	var assets := CampaignVisualAssets.new()
	var config: ChaosConfiguration = _app._chaos_configuration
	for id: StringName in ChaosConfiguration.ROUTES:
		_press("Route_" + String(id))
		var page := _app._screen as ChaosRoutePage
		var template: BattleStage = CampaignContent.MAPS[id]
		var board := page._board
		var field := board.first_contact_field
		_check(board.battle == null and field != null and board.battle_map == template.map and board.routes == template.routes,
			"%s preview uses the exact live map and routes with no simulation" % id)
		_check(_has_landscape(field, template.map, assets), "%s preview has approved backdrop and foreground" % id)
		_check(("Heat enabled" in page._route_info.text) == (id == &"T05") and str(template.routes.size()) in page._route_info.text,
			"%s preview describes its entry count and Heat rules" % id)
		_check(page._buttons[id].button_pressed and page._buttons.values().filter(func(button: Button) -> bool:
			return button.button_pressed).size() == 1, "%s is the only selected route" % id)
		_check(_texture("Mount") != null, "%s route picker has the approved trophy mount" % id)
		await _capture("route-" + String(id).to_lower())
		config.set_quantity(0, &"E01", 2)
		config.set_quantity(0, &"E02", 1)
		_press("ConfigureChaos")
		var plan: OperationPlan = _app._chaos_plan
		plan.configure_campaign(_app._campaign_progress, [PATROL, POST])
		_app._render_chaos_composer()
		_press("OpenModifiers")
		_press("ShowDebuffs")
		_toggle("Modifier_D05", true)
		_press("ApplyModifiers")
		var composer := _app._screen as ChaosComposer
		if id == &"T02":
			_check_wave_and_loadout(assets)
			await _capture("chaos-waves")
			_press("EditLoadout")
			await _capture("chaos-loadout")
			_press("OpenModifiers")
			await _capture("modifiers-buffs")
			_press("ShowDebuffs")
			_check(_texture("ModifierGlyph_D01") == assets.modifier_glyph(&"D01")
				and _find("Modifier_D14").disabled, "The modifier list uses approved glyphs and retains Heat eligibility")
			await _capture("modifiers-debuffs")
			_press("ApplyModifiers")
			composer = _app._screen as ChaosComposer
		_check(not composer._start.disabled, "%s configuration remains legal" % id)
		_press("StartChaos")
		var live := _app._screen as ChaosBattle
		live.set_physics_process(false)
		var sim := live.battle
		_check(live._board.battle_map == template.map and live._board.routes == template.routes
			and _has_landscape(live._board.first_contact_field, template.map, assets)
			and live._board.first_contact_field.full_pack, "%s live Chaos uses the same geometry and full art" % id)
		var patrol := DeployableLevels.definition(PATROL)
		var cell := _first_deployment_cell(sim, patrol)
		_check(not cell.is_empty() and sim.deployment.deploy(patrol, cell[0], -1).is_empty(), "%s accepts a legal Patrolman placement" % id)
		_advance(live, 1210)
		_check(sim.active.size() > 0 and live._board.first_contact_field.enemies.size() > 0,
			"%s spawns a live illustrated enemy" % id)
		_check(live.get_node("%HeatRow").visible == (id == &"T05"), "%s shows Heat only when enabled" % id)
		await _capture("battle-" + String(id).to_lower())
		_press("Pause")
		var before := sim.clock.tick
		_advance(live, 40)
		_check(sim.clock.paused and sim.clock.tick == before and _texture("E01Badge") == assets.badge(&"E01"),
			"%s pause freezes combat and shows the correct Enemy Intel badge" % id)
		if id == &"T02":
			await _capture("chaos-pause")
			_press("PauseSettings")
			await _capture("settings-in-battle")
			_app._battle_settings.request_back()
			_check(sim.clock.paused and live.get_node("%PauseOverlay").visible, "Settings returns to the paused battle")
			_press("ResumeOperation")
			_press("Speed")
			_advance(live, 1)
			_check(sim.clock.tick == before + 2, "Resume restores combat and speed advances two ticks")
			_press("Pause")
		_press("AskAbandon")
		_press("ConfirmAbandon")
		_check(_app._screen is ChaosComposer and _app._campaign_progress.funds() == 10000, "%s abandons without payment" % id)
		_app._go_back()
		config.set_quantity(0, &"E01", 0)
		config.set_quantity(0, &"E02", 0)

func _check_wave_and_loadout(assets: CampaignVisualAssets) -> void:
	for enemy: BattleEnemyDefinition in _app._chaos_configuration.enemies():
		var id := enemy.enemy_id
		var texture := _texture("EnemyBadge_" + String(id).replace(".", "_"))
		_check(texture != null and texture == assets.badge(id), "%s has its own wave badge" % id)
	for id in [PATROL, POST, &"ranger.combat_medic", &"facility.sonic_turret"]:
		_check(_texture("Badge_" + String(id).replace(".", "_")) == assets.badge(id), "%s has the approved loadout badge" % id)
	var manifest: Dictionary = assets.catalog.modifier_glyphs
	for id: String in manifest:
		_check(assets.modifier_glyph(id) != null, "%s has its approved packaged modifier glyph" % id)
	for threshold in [0, 1000, 2000, 3000, 3500]:
		var tier := ChaosScore.tier(threshold)
		var trophy := ChaosTrophy.artwork(tier, 80)
		var mount: TextureRect = trophy.get_node("Mount")
		var emblem := trophy.get_node_or_null("Emblem") as TextureRect
		_check(mount.texture != null and (emblem == null if tier == 0 else
			emblem.texture.resource_path.ends_with("tier_%d.png" % (tier * 1000))), "%d uses the correct W29 mount and tier" % threshold)
		trophy.free()

func _check_chaos_results() -> void:
	_press("Route_T01")
	var config: ChaosConfiguration = _app._chaos_configuration
	config.set_quantity(0, &"E01", 2)
	config.set_quantity(1, &"E01", 1)
	_press("ConfigureChaos")
	var plan: OperationPlan = _app._chaos_plan
	var debuffs: Array[StringName] = [&"D02", &"D03", &"D05", &"D07", &"D08", &"D12", &"D13", &"D15"]
	plan.configure_campaign(_app._campaign_progress, [PATROL, POST])
	plan.restore_modifier_selection(debuffs)
	_app._render_chaos_composer()
	_check(_find("MedalScore").text == "130" and "2,600 Funds" in _find("ChaosPayout").text
		and _find("ProjectedTrophyArt0").visible, "C32-E capped score, payout and projected tier agree")
	await _capture("capped-score")
	_press("StartChaos")
	var field := _app._screen as ChaosBattle
	field.set_physics_process(false)
	var sim := field.battle
	_check(sim.deployment.deploy(DeployableLevels.definition(PATROL), Vector2i(2, 1), -1).is_empty(),
		"Capped victory setup uses a legal T01 Patrolman")
	_advance(field, 10000)
	await process_frame
	_check(sim.configured_defeated == 3 and sim.escaped == 0 and sim.integrity == 100
		and _find("ChaosCreditedFunds").text == "2,600 Funds credited" and _find("ChaosResultTitle").text == "Qualifying clear",
		"Real three-enemy clear matches the preview exactly")
	await _capture("chaos-victory")
	_press("ReviewChaos")
	config.set_quantity(0, &"E01", 0)
	config.set_quantity(1, &"E01", 0)
	config.set_quantity(0, &"E15", 1)
	plan.restore_modifier_selection([&"D05"])
	(_app._screen as ChaosComposer)._update_waves()
	_press("StartChaos")
	field = _app._screen as ChaosBattle
	field.set_physics_process(false)
	_advance(field, 10000)
	await process_frame
	_check(_find("ChaosResultTitle").text == "Defeat" and _find("ChaosCreditedFunds").text == "0 Funds credited"
		and _app._campaign_progress.funds() == 12600, "An unopposed E15 fatal escape pays nothing and keeps the wallet")
	await _capture("chaos-defeat")
	_press("ReviewChaos")
	config.set_quantity(0, &"E15", 0)
	config.set_quantity(0, &"E01", 1)
	(_app._screen as ChaosComposer)._update_waves()
	_press("StartChaos")
	field = _app._screen as ChaosBattle
	field.set_physics_process(false)
	sim = field.battle
	_advance(field, 10000)
	await process_frame
	_check(sim.escaped == 1 and sim.integrity == 90 and _find("ChaosResultTitle").text == "Escape · No payout"
		and _find("ChaosCreditedFunds").text == "0 Funds credited", "Ordinary survival with an escape gets the distinct zero-payout receipt")
	await _capture("chaos-escape")
	_press("ReviewChaos")
	_app._go_back()
	_app._go_back()

func _visit_other_screens() -> void:
	_press("OpenSettings")
	var slider := _find("MasterVolume") as HSlider
	slider.value = 0
	_check(_texture("MasterVolumeIcon") == ProfileSettingsPage.MUTE, "Settings shows the approved mute icon at zero volume")
	slider.value = 80
	_check(_texture("MasterVolumeIcon") == ProfileSettingsPage.SOUND, "Settings restores sound feedback when volume is raised")
	await _capture("settings")
	_app._go_back()
	_press("OpenFAQ")
	await _capture("field-guide")
	_app._go_back()
	_press("Garden")
	await _capture("garden")
	_app._go_back()
	_press("OpenHeadquarters")
	await _capture("headquarters")
	for room_id in ["outreach", "records", "human_resources", "mechanical", "control_room", "finance_room",
			"ecology", "r_d_combat", "r_d_eco", "r_d_guard", "r_d_crisis"]:
		var button := _find("Room_" + room_id) as Button
		if button == null:
			continue
		button.pressed.emit()
		await _capture("hq-" + room_id)
		match room_id:
			"outreach":
				(_app._screen as HeadquartersRoomPage)._activity.pressed.emit()
				_check(_texture("OutreachManagerPortrait") == StoryPortrait.FIRST_CONTACT["portrait.manager"]["briefing"],
					"The Outreach prompt uses the Operations Manager")
				await _capture("outreach")
				await _check_outreach_reactions()
				_app._go_back()
			"records":
				(_app._screen as HeadquartersRoomPage)._activity.pressed.emit()
				for id in RecordsArchivePage.CHAPTER_ART:
					_check(_texture("RecordsChapterArt_" + id) == RecordsArchivePage.CHAPTER_ART[id],
						"%s uses the approved Records chapter illustration" % id)
				await _capture("records")
				var articles: Array[Node] = _app._screen.find_children("Article_*", "Button", true, false)
				var first_article := articles.front() as Button
				first_article.pressed.emit()
				var guide: FieldGuide = _app._guide
				_check(guide != null and guide._body.get_child(0).get_theme_stylebox("panel").texture == FieldGuide.ARTICLE_FRAME,
					"Records opens the illustrated offline article")
				await _capture("records-article")
				guide.back()
				_press("Chapter_scout_sniper")
				await _capture("records-quiz")
				_app._go_back()
				_app._go_back()
			"human_resources", "mechanical":
				(_app._screen as HeadquartersRoomPage)._activity.pressed.emit()
				await _capture("roster-" + room_id)
				_press("Unit_scout_sniper" if room_id == "human_resources" else "Unit_logistics_post")
				await _capture("upgrade-" + room_id)
				_app._go_back()
				_app._go_back()
		_app._go_back()
	_app._go_back()
	_press("OpenCampaign")
	await _capture("story-map")
	_press("Operation_C1_01")
	_check(_texture("Badge_ranger_scout_sniper") != null and _texture("Badge_facility_logistics_post") != null
		and _texture("E01Badge") != null, "First Contact planning shows the mission-supply and Enemy Intel artwork")
	await _capture("story-planner")
	_press("StartOperation")
	await _capture("story-dialogue")

func _check_outreach_reactions() -> void:
	var page := _app._screen as OutreachPage
	var batch := page._session.batch()
	var grades := OutreachPage.REACTIONS.keys()
	for index in grades.size():
		_press("OutreachPrompt%d" % (index + 1))
		var id: String = batch.batch[index]
		var order: Array = batch.choice_order[id]
		var choices: Array = page.catalog.outreach[id].choices
		for option in order.size():
			if choices[order[option]].grade != grades[index]:
				continue
			_press("OutreachAnswer%d" % option)
			break
		_check(_texture("OutreachManagerPortrait") == OutreachPage.REACTIONS[grades[index]],
			"Outreach selects the approved %s response portrait after settlement" % grades[index])
		if grades[index] == "best":
			await _capture("outreach-response")

func _check_boss() -> void:
	_press("OpenChaos")
	_press("Route_T01")
	var config: ChaosConfiguration = _app._chaos_configuration
	config.set_quantity(0, &"E15", 0)
	config.set_quantity(0, &"boss.diversion_captain", 1)
	_press("ConfigureChaos")
	_press("StartChaos")
	var field := _app._screen as ChaosBattle
	field.set_physics_process(false)
	_advance(field, 1500)
	var clock := field.battle.clock
	var tick := clock.tick
	_check(clock.dialogue_open and field._portrait.identity == "portrait.diversion_captain"
		and field._portrait._texture != null, "A live Chaos boss arrival requests its exact approved portrait")
	_advance(field, 30)
	_check(clock.tick == tick, "Boss dialogue art leaves the combat clock frozen")
	await _capture("chaos-boss-dialogue")
	_press("Continue")
	_advance(field, 1)
	_check(not clock.dialogue_open and clock.tick == tick + 1, "Continue resumes boss combat")
	await _capture("chaos-boss")
	_press("Pause")
	_press("AskAbandon")
	_press("ConfirmAbandon")
	_app._go_back()
	_app._go_back()

func _has_landscape(field: FirstContactField, map: BattleMap, assets: CampaignVisualAssets) -> bool:
	if field == null:
		return false
	if map.map_id == &"T01":
		return field._regional == null and field.FOREST != null and field.WOODLAND.size() == 3
	var region := assets.region(map.map_id)
	if region.entries.map(func(entry: Dictionary) -> Vector2i: return Vector2i(FirstContactSkin.vector(entry.cell))) != map.spawns:
		return false
	return field._regional != null and field._regional.layout == region and assets.texture(region.backdrop.texture) != null 		and region.entries.size() == map.spawns.size() and Vector2i(FirstContactSkin.vector(region.exit.cell)) == map.tunnel 		and region.exit.layers.all(func(layer: Dictionary) -> bool: return assets.texture(layer.texture) != null)

func _first_deployment_cell(sim: BattleSimulation, spec: DeploymentSpec) -> Array[Vector2i]:
	for cell in sim._stage.map.ground:
		if cell not in sim._stage.map.spawns and cell != sim._stage.map.tunnel and sim.deployment.placement_error(spec, cell).is_empty():
			return [cell]
	return []

func _advance(field: BattleScene, frames: int) -> void:
	for frame in frames:
		if field.battle.clock.stopped:
			break
		field.battle.clock.advance_frame()
	field._refresh()

func _find(id: String) -> Node:
	for page in _app._content.get_children():
		if page.is_visible_in_tree():
			var node: Node = page.find_child(id, true, false)
			if node != null:
				return node
	return null

func _press(id: String) -> void:
	var button := _find(id) as BaseButton
	_check(button != null and not button.disabled, "Enabled control %s" % id)
	if button != null and not button.disabled:
		button.pressed.emit()

func _toggle(id: String, enabled: bool) -> void:
	var button := _find(id) as BaseButton
	_check(button != null and not button.disabled, "Eligible toggle %s" % id)
	if button != null and not button.disabled:
		button.button_pressed = enabled

func _texture(id: String) -> Texture2D:
	var art := _find(id) as TextureRect
	return art.texture if art != null else null

func _capture(name: String) -> void:
	if _output.is_empty():
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == root.size and image.save_png(_output.path_join(name + ".png")) == OK, name + " rendered at native size")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL ", message)
