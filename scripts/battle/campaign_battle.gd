class_name CampaignBattle
extends BattleScene

var progress: CampaignProgress
var content: CampaignContent
var dialogue_id: String
var _queue: Array[Dictionary] = []
var _active_beat: Dictionary
var _line_index := 0
var _report: Dictionary
var _seen_enemies: Dictionary
var _placed_ranger := false
var _illustrated := false
var _skin: FirstContactSkin
var _portrait := StoryPortrait.new()
var _pose: Label

func _prepare_campaign() -> void:
	%MissionTitle.text = "%s · %s" % [stage.stage_id, operation_plan.operation.title]
	%Legend.text = "%s · Placeholder board art" % stage.map.map_id
	if stage.map.map_id == &"T01" and FirstContactSkin.illustrates_operation(stage.stage_id):
		_skin = FirstContactSkin.new()
		_illustrated = not _skin.registration().is_empty()
	if _illustrated:
		%Legend.hide()
		_hud.illustrate(_skin)
		%DeploymentController.illustrate(_skin)
		_skin.button(%Continue, "button_primary")
		_skin.button(%Skip, "button_secondary")
		%DialogueTitle.add_theme_color_override("font_color", StoryUI.INK)
		%DialogueText.add_theme_color_override("font_color", StoryUI.INK)
		var frame := Panel.new()
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.add_theme_stylebox_override("panel", _skin.panel("dialogue_panel"))
		_dialogue.add_child(frame)
		_dialogue.move_child(frame, 0)
	_portrait.illustrated = _illustrated
	_pose = StoryUI.label("", 17, StoryUI.INK if _illustrated else StoryUI.BEIGE)
	_pose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body: VBoxContainer = %DialogueTitle.get_parent()
	_portrait.custom_minimum_size.y = 230 if _illustrated else 190
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_portrait)
	body.move_child(_portrait, %DialogueText.get_parent().get_index())
	body.add_child(_pose)
	body.move_child(_pose, %DialogueText.get_parent().get_index())

func _open_operation() -> void:
	if _illustrated:
		_board.illustrate_first_contact(_skin, stage.stage_id)
	_queue.clear()
	_report.clear()
	_seen_enemies.clear()
	_placed_ranger = false
	battle.before_wave_first_spawn.connect(func(wave: int) -> void:
		_play_event({"event": "before_wave_first_spawn", "wave": wave})
	)
	battle.wave_resolved.connect(func(wave: int) -> void:
		_play_event({"event": "wave_resolved", "wave": wave})
	)
	battle.enemy_spawned.connect(func(_serial: int, id: StringName) -> void: _seen_enemies[id] = true)
	_play_event({"event": "operation_opening"})

func _open_boss_intro(_id: int, boss: BossSpec) -> void:
	_play_event({"event": "boss_intro", "boss_id": String(boss.enemy_id)})

func _open_boss_phase(id: int, _phase: BossPhase) -> void:
	var enemy := battle.active[id]
	_play_event({"event": "boss_phase_changed", "boss_id": String(enemy.definition.enemy_id), "phase_index": enemy.phase_index})

func _play_event(context: Dictionary) -> void:
	var beat := _find_beat(context)
	if beat.is_empty():
		return
	if beat.trigger.get("presentation_event_id") == "cinematic.c1_03_messenger_withdrawal":
		battle.record_cinematic_withdrawal()
	_queue.append(beat)
	if not battle.clock.dialogue_open:
		_next_beat()

func _find_beat(context: Dictionary) -> Dictionary:
	var fallback: Dictionary = {}
	for beat in operation_plan.operation.dialogue:
		var trigger: Dictionary = beat.trigger
		if trigger.event != context.event:
			continue
		if trigger.get("fallback", false):
			fallback = beat
			continue
		var matches := true
		for field: String in trigger:
			if field != "presentation_event_id" and trigger[field] != context.get(field):
				matches = false
				break
		if matches:
			return beat
	return fallback

func _next_beat() -> void:
	if _queue.is_empty():
		dialogue_id = ""
		battle.clock.dialogue_open = false
		if _report.is_empty():
			_refresh()
			_pause.grab_focus()
		else:
			_dialogue.hide()
			operation_finished.emit(_report.duplicate(true))
		return
	_active_beat = _queue.pop_front()
	dialogue_id = _active_beat.id
	_line_index = 0
	battle.clock.dialogue_open = true
	$Content.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_dialogue.show()
	_render_line()
	%Continue.grab_focus()

func _render_line() -> void:
	var line: Dictionary = _active_beat.lines[_line_index]
	var speaker: Dictionary = content.speakers[line.speaker_id]
	var label: String = speaker.label
	if line.speaker_id == "speaker.leader":
		label += " " + progress.snapshot().leader_name
	%DialogueTitle.text = label
	_portrait.present(speaker.portrait_key, line.pose_key)
	var status := "" if _active_beat.get("status") == "approved_c26_placeholder" else "Draft dialogue · "
	_pose.text = "Story paused" if _illustrated else "Story paused · %sPortrait placeholder · %s" % [status, String(line.pose_key).capitalize()]
	%DialogueText.get_parent().scroll_vertical = 0
	%DialogueText.text = line.text

func close_dialogue() -> void:
	if not battle.clock.dialogue_open:
		return
	_line_index += 1
	if _line_index < _active_beat.lines.size():
		_render_line()
	else:
		_next_beat()

func _skip_dialogue() -> void:
	if battle.clock.dialogue_open:
		_next_beat()

func _update_campaign_tip() -> void:
	if battle.outcome != BattleSimulation.Outcome.RUNNING:
		if not _reported:
			_reported = true
			_publish_result()
		return
	_board.show_starter_guide = stage.stage_id == &"C1-01" and _illustrated and operation_plan.show_hints
	if not operation_plan.show_hints or operation_plan.operation.hints.is_empty() or battle.clock.dialogue_open:
		_tip.text = ""
		return
	var deployment := battle.deployment
	var selected: DeploymentSpec = %DeploymentController.selected_card()
	var ranger_placed := false
	var skill_ready := false
	for unit: DeploymentState.Placement in deployment.placed.values():
		ranger_placed = ranger_placed or unit.spec.is_ranger()
		skill_ready = skill_ready or unit.skill_charges > 0
	_placed_ranger = _placed_ranger or ranger_placed
	var conditions := {
		"starter_post_available": deployment.posts_deployed == 0,
		"can_afford_selected_ranger": not _placed_ranger and %DeploymentController.can_afford_ranger(),
		"first_ranger_placed": _placed_ranger,
		"first_ground_ranger_selected": selected != null and selected.is_melee(),
		"first_elevated_ranger_selected": selected != null and selected.kind == DeploymentSpec.Kind.ELEVATED,
		"first_combat_escape": battle.escaped > 0,
		"first_ranger_skill_ready": skill_ready,
		"combat_medic_selected": selected != null and selected.id == &"ranger.combat_medic",
		"e05_first_seen": _seen_enemies.has(&"E05"),
		"effective_opening_ready": not _seen_enemies.has(&"boss.diversion_captain"),
		"captain_arrived": _seen_enemies.has(&"boss.diversion_captain"),
		"mission_supply_visible": not deployment.placed.has(&"facility.firebreak_beacon"),
	}
	for hint in operation_plan.operation.hints:
		if conditions.get(hint.condition, false):
			_tip.text = hint.text
			return
	_tip.text = ""

func _publish_result() -> void:
	var operation := operation_plan.operation
	var won := battle.outcome == BattleSimulation.Outcome.WON
	var settlement := progress.complete(operation, battle.is_perfect()) if won else {}
	var saved: bool = not settlement.is_empty() if won else progress.abandon_attempt()
	var unlocked := PackedStringArray()
	for id: StringName in settlement.get("unlocked", []):
		var label := content.label_for(id)
		if not content.has_combat_kit(id):
			label += " · combat kit pending"
		unlocked.append(label)
	_tip.text = ""
	_report = {
		"campaign": true, "stage_id": stage.stage_id, "title": operation.title, "outcome": _outcome_label(),
		"integrity": battle.integrity, "defeated": battle.defeated, "escaped": battle.escaped,
		"perfect": battle.is_perfect(), "fatal_escape_id": battle.fatal_escape_id,
		"fatal_escape_name": content.enemy_name(battle.fatal_escape_id),
		"escaped_boss_id": battle.escaped_boss_id, "balance": progress.snapshot().funds,
		"save_failed": not saved, "settlement": settlement, "unlocked": unlocked,
	}
	var context := {"event": "victory" if won else "defeat"}
	if not battle.fatal_escape_id.is_empty():
		context.cause = "fatal_escape"
		context.enemy_id = String(battle.fatal_escape_id)
	if not battle.escaped_boss_id.is_empty():
		context.boss_id = String(battle.escaped_boss_id)
		context.boss_resolution = "escaped"
	var outcome_beat := _find_beat(context)
	if not outcome_beat.is_empty():
		_queue.append(outcome_beat)
	if settlement.get("first_clear", false):
		var epilogue := _find_beat({"event": "after_victory_dialogue", "first_clear_only": true})
		if not epilogue.is_empty():
			_queue.append(epilogue)
	if not battle.clock.dialogue_open:
		_next_beat()
