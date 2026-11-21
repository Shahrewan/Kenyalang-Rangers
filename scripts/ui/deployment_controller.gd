extends Node

@export var opening_rules: LogisticsRules
@export var roster: DeploymentRoster
@export var preview_budget := -1

@onready var _board: BattleBoard = %Board
@onready var _tray: HBoxContainer = %DeploymentTray
@onready var _hint: Label = %PlacementFeedback
@onready var _budget: Label = %PreviewTokens
@onready var _confirm: Button = %ConfirmSkill
@onready var _cancel: Button = %CancelSkill
@onready var _retreat: Button = %Retreat

const NO_POINTER := -2
const MOUSE_POINTER := -1

var state: DeploymentState
var mode := 0
var preview_skills := true
var _simulation: BattleSimulation
var _gesture := DeploymentGesture.new()
var _cards: Array[PanelContainer] = []
var _labels: Array[Label] = []
var _pointer := NO_POINTER
var _retreat_unit: StringName

func _ready() -> void:
	_confirm.pressed.connect(_confirm_skill)
	_cancel.pressed.connect(_cancel_skill)
	_retreat.pressed.connect(_retreat_ranger)
	for spec in roster.entries:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 56)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)
		_cards.append(card)
		_labels.append(label)
		_tray.add_child(card)

func setup(simulation: BattleSimulation, map: BattleMap) -> void:
	_simulation = simulation
	var rules := opening_rules.duplicate() as LogisticsRules
	rules.starter_only = mode == 0 and preview_budget < 0
	rules.yield_percent = 90 if rules.starter_only else 100
	rules.fixed_stockpile = mode == 2
	state = DeploymentState.new(map, simulation.clock, maxi(0, preview_budget), rules)
	state.skill_fired.connect(_skill_fired)
	_board.deployments = state
	_cancel_pointer()
	_hide_retreat()
	_hint.text = "Drag the free Starter Post onto two adjacent elevated tiles." if rules.starter_only else "Drag a card onto the grid."
	var offered: Array[DeploymentSpec] = []
	for spec in roster.entries:
		if _can_show_card(spec):
			offered.append(spec)
	if state.clock.is_running() and not state.has_legal_opening(offered):
		state.clock.stopped = true
		_hint.text = "No affordable legal opening. Choose a different setup."
	_refresh()

func _can_show_card(spec: DeploymentSpec) -> bool:
	var starter_card := spec.logistics_post or spec.id in [&"patrolman", &"scout"]
	return (not state.rules.starter_only or starter_card) and not (state.rules.fixed_stockpile and spec.logistics_post)

func _process(_delta: float) -> void:
	if state == null:
		return
	if not state.clock.is_running():
		_cancel_pointer()
		_hide_retreat()
	elif _pointer != NO_POINTER and _gesture.reveal_hold(Time.get_ticks_msec()):
		_show_retreat(_gesture.unit)
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		_cancel_pointer()
		_hide_retreat()

func _input(event: InputEvent) -> void:
	if state == null or not state.clock.is_running():
		return
	var handled := false
	if event is InputEventScreenTouch:
		if event.canceled and event.index == _pointer:
			_cancel_pointer()
			_hide_retreat()
			handled = true
		else:
			handled = _pointer_button(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		handled = _pointer_motion(event.index, event.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handled = _pointer_button(MOUSE_POINTER, event.position, event.pressed)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		handled = _pointer_motion(MOUSE_POINTER, event.position)
	if handled:
		_refresh()
		get_viewport().set_input_as_handled()

func _pointer_button(id: int, at: Vector2, pressed: bool) -> bool:
	if pressed:
		return _press(id, at)
	if _pointer != id:
		return false
	_release(at)
	_cancel_pointer()
	return true

func _press(id: int, at: Vector2) -> bool:
	if _pointer != NO_POINTER:
		return false
	if _retreat.visible and _retreat.get_global_rect().has_point(at):
		return false
	_hide_retreat()
	var cell: Vector2i = _board.cell_at(at)
	var actor: StringName = state.occupancy.get(cell, &"")
	var card: DeploymentSpec
	for i in _cards.size():
		if _cards[i].visible and _cards[i].get_global_rect().has_point(at):
			card = roster.entries[i]
			break
	var targeting := card == null and not state.armed.is_empty() and _board.get_global_rect().has_point(at)
	if card == null and actor.is_empty() and not targeting:
		return false
	if card != null:
		state.cancel_skill()
	_pointer = id
	_gesture.press(at, Time.get_ticks_msec(), card, actor, targeting)
	return true

func _pointer_motion(id: int, at: Vector2) -> bool:
	if _pointer != id:
		return false
	_gesture.motion(at)
	if _gesture.dragging != null and _gesture.moved:
		_board.preview_spec = _gesture.dragging
		_board.preview_cell = _board.cell_at(at)
		_board.preview_facing = _board.facing_at(at)
		var error := state.placement_error(_gesture.dragging, _board.preview_cell)
		_hint.text = "Release to deploy." if error.is_empty() else error
	return true

func _release(at: Vector2) -> void:
	var cell: Vector2i = _board.cell_at(at)
	var action := _gesture.release(at, Time.get_ticks_msec())
	match action:
		DeploymentGesture.Release.DROP:
			var spec := _gesture.dragging
			var error := state.deploy(spec, cell, _board.facing_at(at))
			_hint.text = "%s deployed." % spec.label if error.is_empty() else error
		DeploymentGesture.Release.TAP:
			if state.occupancy.get(cell, &"") == _gesture.unit:
				if state.build_ticks_left(_gesture.unit) > 0:
					_show_retreat(_gesture.unit)
				elif preview_skills and state.quick_tap(_gesture.unit) and not state.armed.is_empty():
					_hint.text = "Tap a covered tile, then confirm the skill."
		DeploymentGesture.Release.HOLD:
			_show_retreat(_gesture.unit)
		DeploymentGesture.Release.TARGET:
			_hint.text = "Confirm the selected tile." if state.select_target(cell) else "Choose a tile in range."

func _cancel_pointer() -> void:
	_pointer = NO_POINTER
	_gesture.reset()
	_board.preview_spec = null

func _show_retreat(id: StringName) -> void:
	var unit: DeploymentState.Placement = state.placed.get(id)
	var building := state.build_ticks_left(id) > 0
	if unit == null or (not unit.spec.is_ranger() and not building):
		return
	_retreat_unit = id
	var at: Vector2 = _board.cell_center(unit.anchor) + Vector2(20, 10)
	_retreat.position = at.clamp(Vector2.ZERO, (_board.size - _retreat.size).max(Vector2.ZERO))
	_retreat.text = "Cancel build" if building else "Retreat"
	_retreat.show()
	_hint.text = "Cancel to refund the paid Tokens." if building else "Choose Retreat to remove this Ranger."

func _hide_retreat() -> void:
	_retreat.hide()
	_retreat_unit = &""

func _retreat_ranger() -> void:
	if state.cancel_construction(_retreat_unit):
		_hint.text = "Construction cancelled. Paid Tokens refunded."
	elif state.retreat(_retreat_unit):
		_hint.text = "Ranger retreated. Redeploy after the cooldown."
	_hide_retreat()

func _confirm_skill() -> void:
	state.confirm_target()
	_refresh()

func _cancel_skill() -> void:
	state.cancel_skill()
	_hint.text = "Skill targeting cancelled."
	_refresh()

func _skill_fired(id: StringName, target: Vector2i) -> void:
	var unit: DeploymentState.Placement = state.placed[id]
	for enemy_id: int in _simulation.active.keys():
		var enemy := _simulation.active[enemy_id]
		var cell := Vector2i(enemy.grid_position().round())
		if (target == DeploymentState.NO_CELL or target == cell) and state.can_attack(unit, cell, enemy.definition.aerial):
			_simulation.defeat_enemy(enemy_id)
			_hint.text = "%s skill hit a test enemy." % unit.spec.label
			return
	_hint.text = "%s skill activated." % unit.spec.label

func _refresh() -> void:
	_budget.text = "Logistic Tokens: %d" % state.tokens
	if _retreat.visible and _retreat.text == "Cancel build" and state.build_ticks_left(_retreat_unit) == 0:
		_hide_retreat()
	var armed := not state.armed.is_empty()
	_confirm.visible = armed
	_cancel.visible = armed
	_confirm.disabled = not state.clock.is_running() or state.pending_target == DeploymentState.NO_CELL
	_cancel.disabled = not state.clock.is_running()
	for i in _labels.size():
		var spec := roster.entries[i]
		var ticks := state.cooldown_ticks(spec.id)
		_cards[i].visible = _can_show_card(spec)
		var detail := "%d Tokens" % state.cost_for(spec)
		var build := state.build_ticks_left(spec.id)
		if build > 0:
			detail = "Building %ds" % ceili(float(build) / CombatClock.TICKS_PER_SECOND)
		elif state.placed.has(spec.id):
			detail = "Deployed"
		elif spec.logistics_post and state.rules.starter_only and state.posts_deployed > 0:
			detail = "Starter deployed"
		elif spec.logistics_post and state.posts_deployed == 0:
			detail = "Free · instant"
		elif ticks > 0:
			detail = "Cooldown %ds" % ceili(float(ticks) / CombatClock.TICKS_PER_SECOND)
		_labels[i].text = "%s\n%s" % [spec.label, detail]
	_board.queue_redraw()
