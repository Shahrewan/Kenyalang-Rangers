class_name FirstContactField
extends Node2D

const FOREST := preload("res://assets/imported/first_contact/t01_forest_backdrop.jpg")
const WOODLAND := [
	preload("res://assets/imported/first_contact/parts/woodland_exit/woodland_runout.png"),
	preload("res://assets/imported/first_contact/parts/woodland_exit/woodland_trees_back.png"),
	preload("res://assets/imported/first_contact/parts/woodland_exit/woodland_trees_front.png"),
]
const POST_LAYERS := [
	preload("res://assets/imported/first_contact/parts/logistics_post/base.png"),
	preload("res://assets/imported/first_contact/parts/logistics_post/supply_crate.png"),
	preload("res://assets/imported/first_contact/parts/logistics_post/radio.png"),
	preload("res://assets/imported/first_contact/parts/logistics_post/indicator.png"),
]
const RIGS := {
	&"ranger.scout_sniper": preload("res://scenes/units/scout_rig.tscn"),
	&"ranger.patrolman": preload("res://scenes/units/patrolman_rig.tscn"),
	&"E01": preload("res://scenes/units/e01_rig.tscn"),
}

class Actor:
	var rig: Node2D
	var parts: Array[Sprite2D] = []
	var bones: Dictionary[StringName, Bone2D] = {}
	var unit: DeploymentState.Placement
	var enemy: BattleEnemy
	var clip: StringName
	var terminal := false
	var phase := 0.0
	var last_x := 0.0

class Effect:
	var name: String
	var expires: int
	var actor: Actor
	var cell: Vector2
	var target: Vector2
	var origin: Vector2
	var start: int
	var socket: StringName
	var socket_offset: Vector2

var rangers: Dictionary[StringName, Actor] = {}
var enemies: Dictionary[int, Actor] = {}
var _effects: Array[Effect] = []
var _battle: BattleSimulation
var _layout: Dictionary
var _patrolman_sockets := {}
var _board: Control
var _skin: FirstContactSkin

func bind(board: Control, battle: BattleSimulation, skin: FirstContactSkin) -> void:
	_board = board
	_battle = battle
	_skin = skin
	_layout = skin.registration()
	_patrolman_sockets = skin.patrolman_sockets()
	battle.clock.stepped.connect(_step)
	battle.enemy_spawned.connect(_spawned)
	battle.enemy_resolved.connect(_resolved)
	battle.enemy_hit_presented.connect(_enemy_hit)
	battle.enemy_attack_presented.connect(_enemy_attack)
	battle.ranger_combat.attack_presented.connect(_ranger_attack)
	battle.deployment.unit_deployed.connect(_deployed)
	battle.deployment.unit_removed.connect(_removed)
	battle.deployment.unit_hit.connect(_ranger_hit)
	battle.deployment.post_paid.connect(_post_paid)

func _make_actor(asset: StringName) -> Actor:
	var actor := Actor.new()
	actor.rig = RIGS[asset].instantiate()
	# Draw the articulated sprites on the board canvas so the woodland can layer
	# above the complete actors, their effects and health.
	actor.rig.hide()
	add_child(actor.rig)
	for bone: Bone2D in actor.rig.find_children("*", "Bone2D", true, false):
		actor.bones[bone.name] = bone
		actor.parts.append(bone.get_node("Art"))
	actor.parts.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool: return a.z_index < b.z_index)
	return actor

func _play(actor: Actor, clip: StringName) -> void:
	actor.clip = clip
	actor.phase = 0.0
	actor.rig.play_state(clip)

func _spawned(id: int, kind: StringName) -> void:
	if kind != &"E01":
		return
	var actor := _make_actor(kind)
	actor.enemy = _battle.active[id]
	actor.last_x = actor.enemy.grid_position().x
	enemies[id] = actor
	_play(actor, &"Move")

func _deployed(unit: DeploymentState.Placement) -> void:
	if unit.spec.logistics_post:
		_post_paid(unit)
	elif RIGS.has(unit.spec.id):
		var actor := _make_actor(unit.spec.id)
		actor.unit = unit
		actor.rig.set_facing(unit.facing)
		actor.rig.facing_locked = unit.spec.is_melee()
		rangers[unit.id] = actor
		_play(actor, &"Deploy")
		_effect("deploy_dust", Vector2(unit.anchor), 18)
	_board.queue_redraw()

func _removed(unit: DeploymentState.Placement) -> void:
	var actor: Actor = rangers.get(unit.id)
	if actor != null:
		actor.terminal = true
		_play(actor, &"Defeat" if unit.hp == 0 else &"Retreat")
	_board.queue_redraw()

func _resolved(id: int, escaped: bool) -> void:
	var actor: Actor = enemies.get(id)
	if actor == null or actor.terminal:
		return
	actor.terminal = true
	_play(actor, &"Exit" if escaped else &"Defeat")

func _ranger_hit(unit: DeploymentState.Placement) -> void:
	if rangers.has(unit.id):
		_play(rangers[unit.id], &"Hit")

func _enemy_hit(id: int) -> void:
	if enemies.has(id):
		_play(enemies[id], &"Hit")
		_effect("enemy_hit", enemies[id].enemy.grid_position(), 12)

func _enemy_attack(enemy: BattleEnemy) -> void:
	var actor: Actor = enemies.get(_battle.active.find_key(enemy))
	if actor != null:
		_play(actor, &"Attack")

func _ranger_attack(unit: DeploymentState.Placement, target_id: int, clip: StringName) -> void:
	var actor: Actor = rangers.get(unit.id)
	var target: BattleEnemy = _battle.active.get(target_id)
	if actor == null or target == null:
		return
	_play(actor, clip)
	var position := target.grid_position()
	if unit.spec.id == &"ranger.scout_sniper":
		actor.rig.set_facing(-1 if position.x < unit.anchor.x else 1)
		var effect := _effect("shot", Vector2(unit.anchor), 18)
		effect.actor = actor
		effect.target = position - Vector2(0, 0.18)
		var shot: Dictionary = _layout.scout_shot
		effect.socket = StringName(shot.bone)
		effect.socket_offset = FirstContactSkin.vector(shot.socket_local_units)
		var bone := actor.bones[effect.socket]
		var muzzle: Vector2 = actor.rig.get_global_transform().affine_inverse() * (bone.global_transform * effect.socket_offset)
		effect.origin = Vector2(unit.anchor) + Vector2(0.5, 0.86) + muzzle / 80.0
	else:
		var effect := _effect("patrol_strike", Vector2(unit.anchor), 18)
		var socket: Array = _patrolman_sockets.attack_fx
		effect.actor = actor
		effect.socket = StringName(socket[0])
		effect.socket_offset = FirstContactSkin.vector(socket[1])

func _post_paid(unit: DeploymentState.Placement) -> void:
	_effect("post_ready", Vector2(unit.anchor) + Vector2(0.5, 0), 24)

func _effect(name: String, cell: Vector2, ticks: int) -> Effect:
	var effect := Effect.new()
	effect.name = name
	effect.cell = cell
	effect.start = _battle.clock.tick
	effect.expires = effect.start + ticks
	_effects.append(effect)
	return effect

func _step(tick: int, seconds: float) -> void:
	for id: int in enemies.keys():
		if _animate(enemies[id], seconds):
			enemies.erase(id)
	for id: StringName in rangers.keys():
		if _animate(rangers[id], seconds):
			rangers.erase(id)
	for i in range(_effects.size() - 1, -1, -1):
		var effect := _effects[i]
		if tick >= effect.expires or (effect.actor != null and not is_instance_valid(effect.actor.rig)):
			_effects.remove_at(i)
	_board.queue_redraw()

func _animate(actor: Actor, seconds: float) -> bool:
	actor.phase += seconds
	if actor.enemy != null:
		var x := actor.enemy.grid_position().x
		if not is_equal_approx(x, actor.last_x):
			actor.rig.set_facing(1 if x > actor.last_x else -1)
		actor.last_x = x
	actor.rig.advance_combat(seconds)
	var player: AnimationPlayer = actor.rig.player
	if actor.terminal:
		if actor.phase >= player.get_animation(actor.clip).length:
			actor.rig.queue_free()
			return true
		return false
	var blocked := actor.unit.blocking_count > 0 if actor.unit != null else not actor.enemy.blocked_by.is_empty()
	var idle := &"Idle" if actor.unit != null else &"Move"
	var hold := &"Block" if actor.unit != null else &"Blocked"
	var next := hold if blocked else idle
	if actor.clip != next and (actor.clip in [idle, hold] or actor.phase >= player.get_animation(actor.clip).length):
		if actor.unit != null and next == &"Block":
			var effect := _effect("patrol_block", Vector2(actor.unit.anchor), 14)
			var socket: Array = _patrolman_sockets.block_contact_fx
			effect.actor = actor
			effect.socket = StringName(socket[0])
			effect.socket_offset = FirstContactSkin.vector(socket[1])
		_play(actor, next)
	return false

func draw_ground() -> void:
	var fits: Vector2 = _board.size / FOREST.get_size()
	var crop: Vector2 = _board.size / maxf(fits.x, fits.y)
	_board.draw_texture_rect_region(FOREST, Rect2(Vector2.ZERO, _board.size),
		Rect2((FOREST.get_size() - crop) * 0.5, crop))
	var cell: float = _board.tile_size()
	var map: BattleMap = _board.battle_map
	for row: Dictionary in _layout.battle.ground:
		var location := Vector2i(FirstContactSkin.vector(row.cell))
		if map.tile_at(location) != BattleMap.Tile.GROUND:
			continue
		terrain(row.region, _tile(location))
		var direction := FirstContactSkin.vector(row.next_cell) - Vector2(location)
		_board.draw_set_transform(_center(Vector2(location)), direction.angle())
		terrain("route_arrow", Rect2(Vector2.ONE * -cell * 0.16, Vector2.ONE * cell * 0.32))
		_board.draw_set_transform(Vector2.ZERO)
	for row: Dictionary in _layout.battle.raised:
		var location := Vector2i(FirstContactSkin.vector(row.cell))
		if map.tile_at(location) != BattleMap.Tile.ELEVATED:
			continue
		var rect := _tile(location)
		terrain(row.region, rect)
		for id: String in row.exposed_edge_art:
			terrain(id, rect)
		_board.draw_rect(rect.grow(-1.0), Color("#394332a0"), false, 1.0)
	terrain(_layout.battle.entry.region, _tile(map.spawns[0]))
	terrain(_layout.battle.tunnel.region, _tile(map.tunnel))
	_woodland(0)
	_woodland(1)

func terrain(id: String, rect: Rect2, tint := Color.WHITE) -> void:
	_board.draw_texture_rect(_skin.region("terrain", id), rect, false, tint)

func _tile(cell: Vector2i) -> Rect2:
	var scale_px: float = _board.tile_size()
	return Rect2(_board.grid_origin() + Vector2(cell) * scale_px, Vector2.ONE * scale_px)

func _center(cell: Vector2) -> Vector2:
	return _board.grid_origin() + (cell + Vector2.ONE * 0.5) * _board.tile_size()

func _woodland(index: int) -> void:
	var layer: Dictionary = _layout.battle.tunnel.layers[index]
	var scale_px: float = _board.tile_size() / 80.0
	var tile := _tile(_board.battle_map.tunnel)
	var bounds := Rect2(tile.position + FirstContactSkin.vector(layer.offset_units_from_terminal_top_left) * scale_px,
		FirstContactSkin.vector(layer.display_size_units) * scale_px)
	var clipped := Rect2(Vector2.ZERO, _board.size).intersection(bounds)
	if clipped.has_area():
		var source_scale: Vector2 = WOODLAND[index].get_size() / bounds.size
		var source := Rect2((clipped.position - bounds.position) * source_scale, clipped.size * source_scale)
		_board.draw_texture_rect_region(WOODLAND[index], clipped, source)

func draw_post(center: Vector2, tint := Color.WHITE) -> void:
	var scale_px: float = _board.tile_size() / 320.0
	var rect := Rect2(center - Vector2(320, 190) * scale_px, Vector2(640, 288) * scale_px)
	for layer: Texture2D in POST_LAYERS:
		_board.draw_texture_rect(layer, rect, false, tint)

func draw_actors() -> void:
	var scale_px: float = _board.tile_size()
	var drawn: Array[Actor] = []
	drawn.assign(rangers.values())
	drawn.append_array(enemies.values())
	# Escape switches to Exit inside the dense canopy. Its final pose keeps
	# sampling offscreen without bleeding through transparent gaps in the leaves.
	drawn = drawn.filter(func(actor: Actor) -> bool: return actor.clip != &"Exit")
	var stacked := {}
	for actor: Actor in drawn:
		if not is_instance_valid(actor.rig) or actor.rig.is_queued_for_deletion():
			continue
		var anchor := Vector2(actor.unit.anchor) if actor.unit != null else actor.enemy.grid_position()
		var offset := 0.0
		if actor.enemy != null and not actor.enemy.blocked_by.is_empty() and not actor.terminal:
			var key := actor.enemy.blocked_by
			var slot: int = stacked.get(key, 0)
			stacked[key] = slot + 1
			offset = -0.19 if slot == 0 else 0.19
		actor.rig.position = _center(anchor) + Vector2(0, (0.36 + offset) * scale_px)
		actor.rig.scale = Vector2.ONE * scale_px / 80.0
	drawn.sort_custom(func(a: Actor, b: Actor) -> bool: return a.rig.position.y < b.rig.position.y)
	var local: Transform2D = _board.get_global_transform().affine_inverse()
	for actor: Actor in drawn:
		if not is_instance_valid(actor.rig) or actor.rig.is_queued_for_deletion():
			continue
		var alpha := 1.0
		if actor.terminal:
			alpha = 1.0 - clampf(actor.phase / actor.rig.player.get_animation(actor.clip).length, 0.0, 1.0)
		for part: Sprite2D in actor.parts:
			_board.draw_set_transform_matrix(local * part.global_transform)
			_board.draw_texture(part.texture, Vector2.ZERO, Color(1, 1, 1, alpha))
		_board.draw_set_transform(Vector2.ZERO)
		if not actor.terminal:
			var hp := actor.unit.hp if actor.unit != null else actor.enemy.hp
			var maximum := actor.unit.spec.max_hp if actor.unit != null else actor.enemy.definition.max_hp
			_board._draw_health(actor.rig.position + Vector2(0, scale_px * 0.055), scale_px * 0.48, hp, maximum)
			if actor.enemy != null:
				_board._draw_enemy_status(actor.enemy, actor.rig.position - Vector2(0, scale_px * 0.32), scale_px)
	_draw_effects()
	_woodland(2)

func socket_position(actor: Actor, bone: StringName, offset: Vector2) -> Vector2:
	return _board.get_global_transform().affine_inverse() * (actor.bones[bone].global_transform * offset)

func _draw_effects() -> void:
	for effect: Effect in _effects:
		var elapsed := _battle.clock.tick - effect.start
		var at := _center(effect.cell)
		if effect.actor != null:
			if not is_instance_valid(effect.actor.rig) or effect.actor.rig.is_queued_for_deletion():
				continue
			at = socket_position(effect.actor, effect.socket, effect.socket_offset)
		if effect.name == "shot":
			var end := _center(effect.target)
			var start: Vector2 = _board.grid_origin() + effect.origin * _board.tile_size()
			var turn := (end - start).angle()
			if elapsed < 5:
				_fx("scout_muzzle", at, 0.34, turn)
			if elapsed < 12:
				_fx("scout_bolt", start.lerp(end, elapsed / 12.0), 0.56, turn)
			else:
				_fx("scout_impact", end, 0.38)
		elif effect.name != "patrol_strike" or elapsed >= 8:
			_fx(effect.name, at, 0.38)

func _fx(id: String, center: Vector2, width: float, turn := 0.0) -> void:
	var texture := _skin.region("effects", id)
	var extent: Vector2 = texture.get_size() * (_board.tile_size() * width / texture.get_width())
	_board.draw_set_transform(center, turn)
	_board.draw_texture_rect(texture, Rect2(-extent * 0.5, extent), false)
	_board.draw_set_transform(Vector2.ZERO)
