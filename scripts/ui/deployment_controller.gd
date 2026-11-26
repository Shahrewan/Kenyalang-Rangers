extends Node

signal sound_requested(id: String)

const Portrait := preload("res://scripts/ui/deployment_portrait.gd")

@export var opening_rules: LogisticsRules
@export var roster: DeploymentRoster
@export var support_entries: Array[DeploymentSpec]
@export var preview_budget := -1
@export var records_enhancements: Array[StringName]

@onready var _board: BattleBoard = %Board
@onready var _scroll: ScrollContainer = %TrayScroll
@onready var _tray: HBoxContainer = %DeploymentTray
@onready var _hint: Label = %PlacementFeedback
@onready var _confirm: Button = %ConfirmSkill
@onready var _cancel: Button = %CancelSkill
@onready var _retreat: Button = %Retreat

const NO_POINTER := -2
const MOUSE_POINTER := -1

var state: DeploymentState
var mode := 0
var preview_skills := true
var _illustrated_cards := {}
var _badges: Dictionary[StringName, Texture2D] = {}
var _simulation: BattleSimulation
var _gesture := DeploymentGesture.new()
var _entries: Array[DeploymentSpec]
var _cards: Array[PanelContainer] = []
var _labels: Array[Label] = []
var _pointer := NO_POINTER
var _swallow_emulated_mouse := false
var _retreat_unit: StringName
var _offered: Dictionary[StringName, DeploymentSpec] = {}
var _press_at := Vector2.ZERO
var _scroll_start := 0
var _pan_tray := false
var _drag_to_field := false
var _local_notice: PanelContainer
var _notice_text: Label
var _notice_until := 0
var _painted_tick := -1
var _skill_detail: Label
var _inspected_unit: StringName
var _facing_picker: HBoxContainer
var _facing_caption: Label
var _face_left: Button
var _face_right: Button
var _deploy_button: Button
var _dismiss_facing: Button
var _pending_spec: DeploymentSpec
var _pending_cell := DeploymentState.NO_CELL
var _pending_facing := 0

func _ready() -> void:
	_confirm.pressed.connect(_confirm_skill)
	_cancel.pressed.connect(_cancel_skill)
	_retreat.pressed.connect(_retreat_ranger)
	_skill_detail = StoryUI.label("", 18, StoryUI.CREAM)
	_skill_detail.name = "SelectedSkillStatus"
	_skill_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.get_parent().add_child(_skill_detail)
	_hint.get_parent().move_child(_skill_detail, _hint.get_index() + 1)
	_skill_detail.hide()
	_build_facing_picker()
	_local_notice = PanelContainer.new()
	_local_notice.theme_type_variation = &"LightPanel"
	_local_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_text = StoryUI.label("", 18, StoryUI.INK)
	_notice_text.name = "PlacementError"
	_notice_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_notice_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_local_notice.add_child(_notice_text)
	_board.add_child(_local_notice)
	_local_notice.hide()
	_board.resized.connect(_local_notice.hide)
	_entries = roster.entries.duplicate()
	_entries.append_array(support_entries)
	for spec in _entries:
		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var layout := HBoxContainer.new()
		layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_theme_constant_override("separation", 7)
		card.add_child(layout)
		var portrait := Portrait.new() as Control
		portrait.spec = spec
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.custom_minimum_size = Vector2(42, 44)
		layout.add_child(portrait)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 15)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_child(label)
		_cards.append(card)
		_labels.append(label)
		_tray.add_child(card)
	_resize_cards()
	get_viewport().size_changed.connect(_viewport_resized)

func _viewport_resized() -> void:
	_resize_cards()
	cancel_interaction()

func illustrate(skin: FirstContactSkin) -> void:
	var assets := CampaignVisualAssets.new()
	for state_name in ["tray_starter", "tray_ready", "tray_wait"]:
		_illustrated_cards[state_name] = skin.panel(state_name, 15)
	for i in _cards.size():
		var id := _entries[i].id
		_labels[i].add_theme_color_override("font_color", StoryUI.INK)
		var badge: Texture2D
		if skin.registration().thumbnails.regions.has(String(_entries[i].id)):
			badge = skin.region("badge", String(id))
		else:
			badge = assets.badge(id)
		if badge != null:
			_badges[id] = badge
			var portrait = _cards[i].get_child(0).get_child(0)
			portrait.badge = badge
			portrait.queue_redraw()

func _resize_cards() -> void:
	var minimum := Vector2(174, 60).max(StoryUI.android_touch_minimum(_tray))
	for card in _cards:
		card.custom_minimum_size = minimum
	var hit := StoryUI.android_touch_minimum(_tray)
	for button: Button in [_face_left, _face_right, _deploy_button, _dismiss_facing, _retreat, _confirm, _cancel]:
		button.custom_minimum_size = Vector2(maxf(92, hit.x), maxf(60, hit.y))

func _build_facing_picker() -> void:
	_facing_picker = StoryUI.row(_hint.get_parent(), 10)
	_facing_picker.name = "FacingSelection"
	_facing_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_facing_caption = StoryUI.label("", 19, StoryUI.AMBER)
	_facing_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_facing_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_facing_picker.add_child(_facing_caption)
	var group := ButtonGroup.new()
	_face_left = _facing_action("Face left  ←", "FaceLeft", _select_facing.bind(-1))
	_face_right = _facing_action("Face right  →", "FaceRight", _select_facing.bind(1))
	for choice: Button in [_face_left, _face_right]:
		choice.toggle_mode = true
		choice.button_group = group
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deploy_button = _facing_action("Deploy", "ConfirmDeploy", _confirm_deployment, true)
	_deploy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deploy_button.size_flags_stretch_ratio = 0.9
	_dismiss_facing = _facing_action("Cancel", "CancelDeploy", cancel_pending_placement)
	_dismiss_facing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dismiss_facing.size_flags_stretch_ratio = 0.65
	_facing_picker.hide()

func _facing_action(label: String, id: String, callback: Callable, primary := false) -> Button:
	var button := StoryUI.action(label, primary)
	button.name = id
	button.pressed.connect(callback)
	_facing_picker.add_child(button)
	return button

func setup(simulation: BattleSimulation, map: BattleMap, plan: OperationPlan = null) -> void:
	_simulation = simulation
	_inspected_unit = &""
	var rules := opening_rules.duplicate() as LogisticsRules
	_offered.clear()
	if plan != null:
		rules = plan.resolved().opening
		for spec in plan.deployment_entries():
			_offered[spec.id] = spec
	else:
		rules.starter_only = mode == 0 and preview_budget < 0
		rules.yield_percent = 90 if rules.starter_only else 100
		rules.fixed_stockpile = mode == 2
		for spec in _entries:
			var starter := spec.logistics_post or spec.id in [&"patrolman", &"scout"]
			if (not rules.starter_only or starter) and not (rules.fixed_stockpile and spec.logistics_post):
				_offered[spec.id] = spec
	var opening_budget := plan.resolved().tokens if plan != null else maxi(0, preview_budget)
	state = DeploymentState.new(map, simulation.clock, opening_budget, rules, records_enhancements, simulation.effects)
	state.skill_fired.connect(_skill_fired)
	state.hp_restored.connect(func() -> void: sound_requested.emit("support"))
	state.tokens_produced.connect(func() -> void: sound_requested.emit("tokens"))
	state.skill_recharged.connect(func() -> void: sound_requested.emit("skill"))
	_board.deployments = state
	_scroll.scroll_horizontal = 0
	cancel_interaction()
	_local_notice.hide()
	if plan != null and plan.operation.campaign_spec and not plan.operation.hints.is_empty():
		_hint.text = ""
	else:
		_hint.text = "Drag the free Starter Post to two raised tiles." if rules.starter_only else "Drag a card onto the grid."
	var offered: Array[DeploymentSpec] = []
	offered.assign(_offered.values())
	if state.clock.is_running() and not state.has_legal_opening(offered):
		state.clock.stopped = true
		_hint.text = "No affordable legal opening. Choose a different setup."
	_refresh()

func selected_card() -> DeploymentSpec:
	return _gesture.dragging

func is_choosing_facing() -> bool:
	return _pending_spec != null

func can_afford_ranger() -> bool:
	for spec: DeploymentSpec in _offered.values():
		if spec.is_ranger() and state.cost_for(spec) <= state.tokens and state.cooldown_ticks(spec.id) == 0:
			return true
	return false

func _process(_delta: float) -> void:
	if state == null:
		return
	if state.clock.tick >= _notice_until or not state.clock.is_running():
		_local_notice.hide()
	if not state.clock.is_running():
		if _pointer != NO_POINTER or _pending_spec != null or _retreat.visible or not state.armed.is_empty():
			cancel_interaction()
	elif _pointer != NO_POINTER and _gesture.reveal_hold(Time.get_ticks_msec()):
		_show_retreat(_gesture.unit)
	if state.clock.tick != _painted_tick:
		_refresh()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] and is_node_ready():
		cancel_interaction()

func _input(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		_handle_emulated_mouse(event)
		return
	if state == null or not state.clock.is_running():
		return
	var handled := false
	if event is InputEventScreenTouch:
		if event.canceled:
			if event.index == _pointer:
				cancel_interaction()
			handled = true
		elif _pointer != NO_POINTER and event.index != _pointer:
			handled = true
		else:
			handled = _pointer_button(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		handled = _pointer != NO_POINTER and event.index != _pointer
		if not handled:
			handled = _pointer_motion(event.index, event.position)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and _tray_clip().has_point(event.position):
			_scroll.scroll_horizontal += 120 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -120
			handled = true
		elif event.button_index == MOUSE_BUTTON_LEFT:
			handled = _pointer_button(MOUSE_POINTER, event.position, event.pressed)
	elif event is InputEventMouseMotion:
		handled = _pointer_motion(MOUSE_POINTER, event.position)
	if handled:
		if event is InputEventScreenDrag or event is InputEventMouseMotion:
			_board.queue_redraw()
		else:
			_refresh()
		get_viewport().set_input_as_handled()

func _handle_emulated_mouse(event: InputEvent) -> void:
	# Godot delivers the emulated mouse event before its native touch counterpart.
	# Capture the pair for field/tray gestures while leaving ordinary GUI taps to Godot.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_swallow_emulated_mouse = state != null and state.clock.is_running() and (
				_pointer != NO_POINTER or _is_field_gesture(event.position))
		if _swallow_emulated_mouse:
			get_viewport().set_input_as_handled()
		if not event.pressed:
			_swallow_emulated_mouse = false
	elif event is InputEventMouseMotion and _swallow_emulated_mouse:
		get_viewport().set_input_as_handled()

func _is_field_gesture(at: Vector2) -> bool:
	if _pending_spec != null or (_retreat.visible and _retreat.get_global_rect().has_point(at)):
		return false
	return _tray_clip().has_point(at) or not state.interaction_id(_board.cell_at(at)).is_empty() or (
		not state.armed.is_empty() and _board.get_global_rect().has_point(at))

func _pointer_button(id: int, at: Vector2, pressed: bool) -> bool:
	if pressed:
		return _press(id, at)
	if _pointer != id:
		return false
	_pointer_motion(id, at)
	if not _pan_tray:
		_release(at)
	_cancel_pointer()
	return true

func _press(id: int, at: Vector2) -> bool:
	if _pointer != NO_POINTER or not _is_field_gesture(at):
		return false
	_hide_retreat()
	var cell: Vector2i = _board.cell_at(at)
	var actor := state.interaction_id(cell)
	var card: DeploymentSpec
	if _tray_clip().has_point(at):
		for i in _cards.size():
			if _cards[i].visible and _cards[i].get_global_rect().has_point(at):
				card = _offered.get(_entries[i].id)
				break
	var targeting := card == null and not state.armed.is_empty() and _board.get_global_rect().has_point(at)
	var in_tray := _tray_clip().has_point(at)
	if not targeting:
		_inspected_unit = actor if card == null else &""
	if card == null and actor.is_empty() and not targeting and not in_tray:
		return false
	_local_notice.hide()
	if card != null:
		state.cancel_skill()
	_pointer = id
	_press_at = at
	_scroll_start = _scroll.scroll_horizontal
	_gesture.press(at, Time.get_ticks_msec(), card, actor, targeting)
	return true

func _pointer_motion(id: int, at: Vector2) -> bool:
	if _pointer != id:
		return false
	_gesture.motion(at)
	if _gesture.moved and _tray_clip().has_point(_press_at) and not _drag_to_field:
		var movement := at - _press_at
		if not _pan_tray and absf(movement.x) > absf(movement.y) and _tray_clip().has_point(at):
			_pan_tray = true
		elif not _pan_tray and _gesture.dragging != null:
			_drag_to_field = true
		if _pan_tray:
			_scroll.scroll_horizontal = roundi(_scroll_start - movement.x)
			return true
	if _gesture.dragging != null and _gesture.moved:
		_board.preview_spec = _gesture.dragging
		_board.preview_cell = _board.cell_at(at)
		_board.preview_facing = 0
		_board.preview_badge = null
		var error := state.placement_error(_gesture.dragging, _board.preview_cell)
		if not error.is_empty():
			_hint.text = error
		else:
			_hint.text = "Release to choose facing." if _gesture.dragging.is_melee() else "Release to deploy."
	return true

func _tray_clip() -> Rect2:
	var clip := _scroll.get_global_rect()
	var bar := _scroll.get_h_scroll_bar()
	if bar.visible:
		clip.size.y = maxf(0.0, bar.global_position.y - clip.position.y)
	return clip

func _release(at: Vector2) -> void:
	var cell: Vector2i = _board.cell_at(at)
	var action := _gesture.release(at, Time.get_ticks_msec())
	match action:
		DeploymentGesture.Release.DROP:
			var spec := _gesture.dragging
			if spec.is_melee():
				var error := state.placement_error(spec, cell)
				if error.is_empty():
					_pending_spec = spec
					_pending_cell = cell
					_select_facing(0)
				else:
					_placement_failed(error, at)
			else:
				_deploy(spec, cell, 1, at)
		DeploymentGesture.Release.TAP:
			if state.interaction_id(cell) == _gesture.unit:
				if state.build_ticks_left(_gesture.unit) > 0:
					_show_retreat(_gesture.unit)
				else:
					_tap_skill(_gesture.unit)
		DeploymentGesture.Release.HOLD:
			if _retreat.visible and _gesture.moved and _retreat.get_global_rect().has_point(at):
				_retreat_ranger()
			else:
				_show_retreat(_gesture.unit)
		DeploymentGesture.Release.TARGET:
			if state.select_target(cell):
				_hint.text = "Confirm the selected tile."
			else:
				_show_local_error("Choose a tile in range.", at)
				_hint.text = "Choose a highlighted tile, then confirm."

func _select_facing(direction: int) -> void:
	if _pending_spec == null or not state.clock.is_running():
		return
	_pending_facing = direction
	_board.preview_spec = _pending_spec
	_board.preview_cell = _pending_cell
	_board.preview_facing = direction
	_board.preview_badge = _badges.get(_pending_spec.id)
	_board.preview_locked = true
	_face_left.set_pressed_no_signal(direction == -1)
	_face_right.set_pressed_no_signal(direction == 1)
	_refresh()

func _confirm_deployment() -> void:
	if _pending_spec == null or _pending_facing == 0:
		return
	var spec := _pending_spec
	var cell := _pending_cell
	var facing := _pending_facing
	_clear_pending()
	_deploy(spec, cell, facing, _board.get_global_transform_with_canvas() * _board.cell_center(cell))
	_refresh()

func _deploy(spec: DeploymentSpec, cell: Vector2i, facing: int, at: Vector2) -> void:
	var error := state.deploy(spec, cell, facing)
	if error.is_empty():
		sound_requested.emit("deploy")
		_hint.text = "%s deployed." % spec.label
	else:
		_placement_failed(error, at)

func _placement_failed(error: String, at: Vector2) -> void:
	_show_local_error(error, at)
	_hint.text = "%s No Tokens spent." % error

func cancel_pending_placement() -> bool:
	if _pending_spec == null:
		return false
	_clear_pending()
	_hint.text = "Placement cancelled · no Tokens spent."
	_refresh()
	return true

func _clear_pending() -> void:
	_pending_spec = null
	_pending_cell = DeploymentState.NO_CELL
	_pending_facing = 0
	_clear_preview()

func cancel_interaction() -> void:
	if state == null:
		return
	if _pending_spec != null or _gesture.dragging != null:
		_hint.text = "Placement cancelled · no Tokens spent."
	_cancel_pointer()
	_clear_pending()
	_hide_retreat()
	state.cancel_skill()
	_local_notice.hide()
	_refresh_controls()
	_board.queue_redraw()

func _show_local_error(message: String, at: Vector2) -> void:
	_notice_text.text = message
	_local_notice.reset_size()
	var canvas := _board.get_global_transform_with_canvas()
	var local := canvas.affine_inverse() * at if at.is_finite() and not is_zero_approx(canvas.determinant()) else _board.size * 0.5
	var offset := Vector2(12, -_local_notice.size.y - 12)
	_local_notice.position = (local + offset).clamp(Vector2.ZERO, (_board.size - _local_notice.size).max(Vector2.ZERO))
	_notice_until = state.clock.tick + CombatClock.TICKS_PER_SECOND * 3
	_local_notice.show()
	sound_requested.emit("invalid")

func _cancel_pointer() -> void:
	_pointer = NO_POINTER
	_pan_tray = false
	_drag_to_field = false
	_gesture.reset()
	if _pending_spec == null:
		_clear_preview()

func _clear_preview() -> void:
	_board.preview_spec = null
	_board.preview_cell = DeploymentState.NO_CELL
	_board.preview_facing = 0
	_board.preview_badge = null
	_board.preview_locked = false

func _show_retreat(id: StringName) -> void:
	_inspected_unit = id
	var unit: DeploymentState.Placement = state.placed.get(id)
	var building := state.build_ticks_left(id) > 0
	if unit == null or (not unit.spec.is_ranger() and not building):
		return
	_retreat_unit = id
	_retreat.text = "Cancel build" if building else "Retreat"
	_retreat.reset_size()
	var anchor := _board.cell_center(unit.anchor)
	var gap := _board.tile_size() * 0.5 + 8
	var x := anchor.x + gap
	if x + _retreat.size.x > _board.size.x:
		x = anchor.x - gap - _retreat.size.x
	var at := Vector2(x, anchor.y - _retreat.size.y * 0.5)
	_retreat.position = at.clamp(Vector2.ZERO, (_board.size - _retreat.size).max(Vector2.ZERO))
	_retreat.show()
	_hint.text = "Cancel to refund the paid Tokens." if building else "Choose Retreat to remove this Ranger."
	if unit.arrival_tick > 0:
		_hint.text = "Incoming · both ground tiles reserved. Retreat powers up the next drop."
	elif unit.spec.is_melee():
		_hint.text = "Blocking %d · Attacks %s" % [unit.blocking_count, "left" if unit.facing < 0 else "right"]

func _hide_retreat() -> void:
	_retreat.hide()
	_retreat_unit = &""

func _retreat_ranger() -> void:
	if state.cancel_construction(_retreat_unit):
		_hint.text = "Construction cancelled. Paid Tokens refunded."
	elif state.retreat(_retreat_unit):
		_hint.text = "Ranger retreated. Redeploy after the cooldown."
	_hide_retreat()
	_refresh()

func _tap_skill(id: StringName) -> void:
	var unit: DeploymentState.Placement = state.placed.get(id)
	if unit == null:
		return
	if unit.ranger != null or unit.facility != null:
		if unit.spec.skill == DeploymentSpec.Skill.NONE:
			if unit.facility != null:
				_hint.text = "%s · %d/%d HP" % [unit.spec.label, unit.hp, unit.spec.max_hp]
			return
		if not _simulation.tap_unit(id):
			_show_local_error(state.last_skill_error, _board.get_global_transform_with_canvas() * _board.cell_center(unit.anchor))
			_hint.text = state.last_skill_error
			return
	elif not preview_skills or not state.quick_tap(id):
		return
	if not state.armed.is_empty():
		_hint.text = "Tap a covered tile, then confirm the skill."

func _confirm_skill() -> void:
	var unit: DeploymentState.Placement = state.placed.get(state.armed)
	if unit == null:
		return
	var cell := state.pending_target if state.pending_target != DeploymentState.NO_CELL else unit.anchor
	var live := unit.ranger != null or unit.facility != null
	var fired := _simulation.confirm_skill_target() if live else state.confirm_target()
	if not fired:
		_show_local_error(state.last_skill_error, _board.get_global_transform_with_canvas() * _board.cell_center(cell))
		_hint.text = state.last_skill_error
	_refresh()

func _cancel_skill() -> void:
	state.cancel_skill()
	_hint.text = "Skill targeting cancelled."
	_refresh()

func _skill_fired(id: StringName, target: Vector2i) -> void:
	sound_requested.emit("skill")
	var unit: DeploymentState.Placement = state.placed.get(id)
	if unit == null:
		return
	if unit.facility != null:
		if unit.facility.role == FacilitySpec.Role.SPECIALIST_CALLTOWER:
			_hint.text = "Next Specialist deployment costs %d fewer Tokens." % state.specialist_discount
		else:
			_hint.text = "Medic kit used."
		return
	if unit.ranger != null:
		_hint.text = "%s used %s." % [unit.spec.label, unit.ranger.active_skill.label]
		return
	for enemy_id: int in _simulation.active.keys():
		var enemy := _simulation.active[enemy_id]
		var cell := Vector2i(enemy.grid_position().round())
		if (target == DeploymentState.NO_CELL or target == cell) and state.can_attack(unit, cell, enemy.definition.aerial):
			_simulation.defeat_enemy(enemy_id)
			_hint.text = "%s skill hit a test enemy." % unit.spec.label
			return
	_hint.text = "%s skill activated." % unit.spec.label

func _refresh() -> void:
	_painted_tick = state.clock.tick
	_refresh_controls()
	_refresh_tray()
	_board.queue_redraw()

func _refresh_controls() -> void:
	var choosing := _pending_spec != null
	_facing_picker.visible = choosing
	_hint.visible = not choosing
	if choosing:
		_facing_caption.text = "%s · %d Tokens" % [_pending_spec.label, state.cost_for(_pending_spec)]
		_deploy_button.disabled = _pending_facing == 0 or not state.clock.is_running()
	var selected: DeploymentState.Placement = state.placed.get(_inspected_unit)
	var inspected := BattleSkillStatus.read(selected, state)
	_skill_detail.visible = inspected != null and not choosing
	if inspected != null:
		_skill_detail.text = inspected.detail()
	if _retreat.visible and (not state.placed.has(_retreat_unit) or (_retreat.text == "Cancel build" and state.build_ticks_left(_retreat_unit) == 0)):
		_hide_retreat()
	var armed := not state.armed.is_empty() and not choosing
	_confirm.visible = armed
	_cancel.visible = armed
	_confirm.disabled = not state.clock.is_running() or state.pending_target == DeploymentState.NO_CELL
	_cancel.disabled = not state.clock.is_running()

func _refresh_tray() -> void:
	var deployed := {}
	for unit: DeploymentState.Placement in state.placed.values():
		var copies: Array = deployed.get_or_add(unit.spec.id, [])
		copies.append(unit)
	for i in _labels.size():
		var spec: DeploymentSpec = _offered.get(_entries[i].id)
		_cards[i].visible = spec != null
		if spec == null:
			continue
		var ticks := state.cooldown_ticks(spec.id)
		var copies: Array = deployed.get(spec.id, [])
		if not _illustrated_cards.is_empty():
			var key := "tray_wait"
			if spec.logistics_post and state.posts_deployed == 0:
				key = "tray_starter"
			elif ticks == 0 and state.tokens >= state.cost_for(spec) and not (spec.logistics_post and state.rules.starter_only):
				key = "tray_ready"
			var panel: StyleBox = _illustrated_cards[key]
			if _cards[i].get_theme_stylebox("panel") != panel:
				_cards[i].add_theme_stylebox_override("panel", panel)
		var detail := "%d Tokens" % state.cost_for(spec)
		if spec.logistics_post and state.rules.starter_only and state.posts_deployed > 0:
			detail = "Starter deployed"
		elif spec.logistics_post and state.posts_deployed == 0:
			detail = "Free · instant"
		elif ticks > 0:
			detail = "Cooldown %ds" % ceili(float(ticks) / CombatClock.TICKS_PER_SECOND)
		if not copies.is_empty() and not (spec.logistics_post and state.rules.starter_only):
			detail += " · %d on field" % copies.size()
		if copies.size() == 1 and not (spec.logistics_post and state.rules.starter_only):
			var unit: DeploymentState.Placement = copies[0]
			var build := state.build_ticks_left(unit.id)
			var status := "Building %ds" % ceili(float(build) / CombatClock.TICKS_PER_SECOND) if build > 0 else _deployed_card_detail(unit)
			if status != "Deployed":
				detail += "\n" + status
		_labels[i].text = "%s\n%s" % [spec.label, detail]

func _deployed_card_detail(unit: DeploymentState.Placement) -> String:
	var tick := state.clock.tick
	var skill := BattleSkillStatus.read(unit, state)
	if skill != null:
		match skill.mode:
			BattleSkillStatus.Mode.READY: return "Skill ready"
			BattleSkillStatus.Mode.RECOVERING: return "Skill recovering"
			BattleSkillStatus.Mode.LOCKED: return "Skill locked"
			BattleSkillStatus.Mode.SPENT: return "Skill spent"
	if tick < unit.knocked_down_until:
		return "Knocked down"
	if tick < unit.entangled_until:
		return "Entangled"
	if tick < unit.jammed_until:
		return "Skill jammed"
	if tick < unit.attack_slow_until:
		return "Attack rate reduced"
	if unit.facility != null:
		match unit.facility.role:
			FacilitySpec.Role.MEDIC_CABIN:
				return "%d/%d kits" % [unit.stock, unit.facility.stock_capacity]
			FacilitySpec.Role.SKILL_RELAY, FacilitySpec.Role.DISPATCH_RELAY:
				var seconds := ceili(float(unit.next_utility_tick - state.clock.tick) / CombatClock.TICKS_PER_SECOND)
				return "Pulse in %ds" % maxi(0, seconds)
			FacilitySpec.Role.SENTRY_TOWER:
				return "Mount open" if unit.mounted_ranger.is_empty() else "Ranger mounted"
			FacilitySpec.Role.SPECIALIST_CALLTOWER:
				if state.specialist_discount > 0:
					return "−%d Tokens next Specialist" % state.specialist_discount
				return "Discount ready" if unit.stock > 0 else "Preparing discount"
	return "Deployed"
