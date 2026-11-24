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
# E02 and E03 share the W29 fist pivot and attack_fx registration.
const ENEMY_FIST_OFFSET := Vector2(-0.318, 2.679)
const MEDIC_CASE_OFFSET := Vector2(18, 1)
const TURRET_ANCHOR := Vector2(80, 67)
const TURRET_SOCKET := Vector2(108, 31)
const HEAL := preload("res://assets/imported/effects/w29/heal.png")
const ACTOR_FOOT_OFFSET := 0.36
const TOWER_LIFT := 0.44
const BOSS_PHASE_CLIPS := {
	&"boss.diversion_captain": &"Rally",
	&"boss.illegal_logging_foreman": &"Overheat",
	&"boss.poacher_leader": &"Surge",
}
const ABILITY_CLIPS := {
	&"E07": [&"Jam", "emp"],
	&"E09": [&"Mark", "marked"],
	&"E10": [&"Cast", "snared"],
	&"E13": [&"Breach", "knockdown"],
}

class Actor:
	var rig: Node2D
	var parts: Array[Sprite2D] = []
	var bones: Dictionary[StringName, Bone2D] = {}
	var unit: DeploymentState.Placement
	var enemy: BattleEnemy
	var clip: StringName
	var terminal := false
	var escaped := false
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

class Turret:
	var rig: Node2D
	var player: AnimationPlayer
	var parts: Array[Sprite2D] = []
	var unit: DeploymentState.Placement
	var anchor := TURRET_ANCHOR
	var clip: StringName
	var phase := 0.0

var rangers: Dictionary[StringName, Actor] = {}
var enemies: Dictionary[int, Actor] = {}
var turrets: Dictionary[StringName, Turret] = {}
var _effects: Array[Effect] = []
var _battle: BattleSimulation
var _layout: Dictionary
var _patrolman_sockets := {}
var _board: Control
var _skin: FirstContactSkin
var _poacher_rig: PackedScene
var _runner_rig: PackedScene
var _medic_rig: PackedScene
var _turret_rig: PackedScene
var _assets: CampaignVisualAssets
var _regional: CampaignRegionArt
var full_pack := false

func bind(board: Control, battle: BattleSimulation, skin: FirstContactSkin, stage_id: StringName) -> void:
	_board = board
	_battle = battle
	_skin = skin
	_layout = skin.registration()
	_patrolman_sockets = skin.patrolman_sockets()
	full_pack = not FirstContactSkin.is_pilot(stage_id)
	if full_pack:
		_assets = CampaignVisualAssets.new()
		if not _assets.region(board.battle_map.map_id).is_empty():
			_regional = CampaignRegionArt.new(board, skin, _assets)
		battle.ranger_combat.healing_presented.connect(_heal_presented.bind(&"Attack"))
		battle.facility_combat.sonic_attack_presented.connect(_turret_attack)
		battle.facility_combat.action_presented.connect(_facility_action)
		battle.facility_combat.repair_presented.connect(_repaired)
		battle.enemy_ability_presented.connect(_enemy_ability)
		battle.boss_phase_changed.connect(_boss_phase)
		battle.boss_captured.connect(_captured)
		battle.heat_overflow.connect(_heat_overflow)
		battle.deployment.skill_fired.connect(_skill)
	elif stage_id != &"C1-01":
		_poacher_rig = _w29_rig(FirstContactSkin.POACHER)
	if stage_id == FirstContactSkin.NARROW_ESCAPE:
		_runner_rig = _w29_rig(FirstContactSkin.RUNNER)
		_medic_rig = _w29_rig(FirstContactSkin.MEDIC)
		_turret_rig = _w29_rig(FirstContactSkin.SONIC)
		battle.ranger_combat.healing_presented.connect(_heal_presented.bind(&"Attack"))
		battle.facility_combat.sonic_attack_presented.connect(_turret_attack)
		battle.deployment.skill_fired.connect(_active_treatment)
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

func _w29_rig(id: StringName) -> PackedScene:
	var art := FirstContactSkin.w29_art(id)
	if art.has("animation") and not FileAccess.file_exists(art.animation):
		return null
	return FirstContactSkin.optional_art(art.get("rig", ""), "PackedScene") as PackedScene

func _make_actor(scene: PackedScene) -> Actor:
	var actor := Actor.new()
	actor.rig = scene.instantiate()
	# Draw the articulated sprites on the board canvas so the woodland can layer
	# above the complete actors, their effects and health.
	actor.rig.hide()
	add_child(actor.rig)
	for bone: Bone2D in actor.rig.find_children("*", "Bone2D", true, false):
		actor.bones[bone.name] = bone
		var art := bone.get_node_or_null("Art") as Sprite2D
		if art != null:
			actor.parts.append(art)
	actor.parts.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool: return a.z_index < b.z_index)
	return actor

func _play(actor: Actor, clip: StringName) -> void:
	if not actor.rig.player.has_animation(clip):
		if not actor.clip.is_empty():
			return
		clip = actor.rig.default_state
	actor.clip = clip
	actor.phase = 0.0
	actor.rig.play_state(clip)

func _spawned(id: int, kind: StringName) -> void:
	var scene: PackedScene = RIGS.get(kind)
	if full_pack:
		if scene == null:
			scene = _assets.rig(_assets.actor(kind))
	else:
		match kind:
			FirstContactSkin.POACHER:
				scene = _poacher_rig
			FirstContactSkin.RUNNER:
				scene = _runner_rig
	if scene == null:
		return
	var actor := _make_actor(scene)
	actor.enemy = _battle.active[id]
	actor.last_x = actor.enemy.grid_position().x
	enemies[id] = actor
	_play(actor, &"Move")
	if full_pack and actor.enemy.boss != null:
		_effect("boss_phase", actor.enemy.grid_position(), 34)

func _deployed(unit: DeploymentState.Placement) -> void:
	if full_pack and unit.facility != null:
		var facility_rig := _assets.rig(_assets.facility(unit.spec.id))
		if facility_rig != null:
			_deploy_turret(unit, facility_rig)
	elif unit.spec.logistics_post:
		if _battle.deployment.build_ticks_left(unit.id) == 0:
			_post_paid(unit)
	elif unit.spec.id == FirstContactSkin.SONIC and _turret_rig != null:
		_deploy_turret(unit, _turret_rig)
	else:
		var scene: PackedScene = _medic_rig if unit.spec.id == FirstContactSkin.MEDIC else RIGS.get(unit.spec.id)
		if scene == null and full_pack:
			scene = _assets.rig(_assets.actor(unit.spec.id))
		if scene == null:
			return
		var actor := _make_actor(scene)
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
	var turret: Turret = turrets.get(unit.id)
	if turret != null:
		if unit.hp == 0:
			_play_turret(turret, &"Destroyed")
		else:
			turret.rig.queue_free()
			turrets.erase(unit.id)
	_board.queue_redraw()

func _resolved(id: int, escaped: bool) -> void:
	var actor: Actor = enemies.get(id)
	if actor == null or actor.terminal:
		return
	actor.terminal = true
	actor.escaped = escaped
	_play(actor, &"Exit" if escaped else &"Defeat")

func _ranger_hit(unit: DeploymentState.Placement) -> void:
	if rangers.has(unit.id):
		_play(rangers[unit.id], &"Hit")
	var turret: Turret = turrets.get(unit.id)
	if turret != null:
		var building := _battle.deployment.build_ticks_left(unit.id) > 0
		_play_turret(turret, &"ConstructionUnderSiege" if building else &"UnderSiege")

func _enemy_hit(id: int) -> void:
	if enemies.has(id):
		_play(enemies[id], &"Hit")
		_effect("enemy_hit", enemies[id].enemy.grid_position(), 12)

func _enemy_attack(enemy: BattleEnemy) -> void:
	var actor: Actor = enemies.get(_battle.active.find_key(enemy))
	if actor != null:
		_play(actor, &"Attack")
		if full_pack:
			var profile := enemy.definition.attack_profile
			var cue := "enemy_hit"
			if profile != null and profile.kind != EnemyAttackProfile.Kind.MELEE:
				cue = "siege" if profile.kind == EnemyAttackProfile.Kind.SIEGE else "enemy_shot"
			_socket_effect(actor, cue, enemy.grid_position(), "attack_fx", 13)
		elif enemy.definition.enemy_id in [FirstContactSkin.POACHER, FirstContactSkin.RUNNER]:
			var effect := _effect("poacher_strike", enemy.grid_position(), 12)
			effect.actor = actor
			effect.socket = &"hand_near"
			effect.socket_offset = ENEMY_FIST_OFFSET

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
		effect.origin = Vector2(unit.anchor) + Vector2(0.5, 0.5 + _foot_offset(actor)) + muzzle / 80.0
	elif full_pack and unit.spec.id != &"ranger.patrolman":
		if not unit.spec.is_melee():
			actor.rig.set_facing(-1 if position.x < unit.anchor.x else 1)
		_socket_effect(actor, "enemy_hit", Vector2(unit.anchor), "attack_fx", 18)
	else:
		var effect := _effect("patrol_strike", Vector2(unit.anchor), 18)
		var socket: Array = _patrolman_sockets.attack_fx
		effect.actor = actor
		effect.socket = StringName(socket[0])
		effect.socket_offset = FirstContactSkin.vector(socket[1])

func _post_paid(unit: DeploymentState.Placement) -> void:
	if full_pack and turrets.has(unit.id):
		_play_turret(turrets[unit.id], &"Active")
	_effect("post_ready", Vector2(unit.anchor) + Vector2(0.5, 0), 24)

func _heal_presented(unit: DeploymentState.Placement, target: Vector2i, clip: StringName) -> void:
	var actor: Actor = rangers.get(unit.id)
	if actor != null:
		_play(actor, clip)
		var effect := _effect("treatment", Vector2(unit.anchor), 27)
		effect.actor = actor
		effect.target = Vector2(target)
		effect.socket = &"treatment_case"
		effect.socket_offset = MEDIC_CASE_OFFSET

func _active_treatment(id: StringName, target: Vector2i) -> void:
	var unit: DeploymentState.Placement = _battle.deployment.placed.get(id)
	if unit != null and unit.spec.id == FirstContactSkin.MEDIC:
		_heal_presented(unit, target, &"Skill")

func _skill(id: StringName, target: Vector2i) -> void:
	var unit: DeploymentState.Placement = _battle.deployment.placed.get(id)
	if unit == null:
		return
	if unit.spec.id in [&"ranger.scout_sniper", FirstContactSkin.MEDIC]:
		_active_treatment(id, target)
	elif unit.facility != null:
		var cue := "heal" if unit.facility.role == FacilitySpec.Role.MEDIC_CABIN else "wallet_credit"
		_facility_action(unit, Vector2(target), cue)
	elif rangers.has(id):
		var actor := rangers[id]
		_play(actor, &"Skill")
		var cue := "patrol_block"
		if unit.ranger.active_skill.effect == RangerSkill.Effect.EMP_FIELD:
			cue = "emp"
		_socket_effect(actor, cue, Vector2(unit.anchor), "attack_fx", 18)

func _socket_effect(actor: Actor, name: String, at: Vector2, cue: String, ticks: int) -> void:
	var effect := _effect(name, at, ticks)
	var id := actor.unit.spec.id if actor.unit != null else actor.enemy.definition.enemy_id
	var socket := _assets.socket(id, cue)
	if not socket.is_empty() and actor.bones.has(StringName(socket[0])):
		effect.actor = actor
		effect.socket = StringName(socket[0])
		effect.socket_offset = FirstContactSkin.vector(socket[1])

func _enemy_ability(enemy: BattleEnemy, target: Vector2i) -> void:
	var cue: Array = ABILITY_CLIPS.get(enemy.definition.enemy_id, [])
	var actor: Actor = enemies.get(_battle.active.find_key(enemy))
	if actor != null and not cue.is_empty():
		_play(actor, cue[0])
		_effect(cue[1], Vector2(target), 24)

func _boss_phase(id: int, _phase: BossPhase) -> void:
	var actor: Actor = enemies.get(id)
	if actor != null:
		_play(actor, BOSS_PHASE_CLIPS[actor.enemy.definition.enemy_id])
		_effect("boss_phase", actor.enemy.grid_position(), 34)

func _captured(id: int) -> void:
	if enemies.has(id):
		_play(enemies[id], &"Captured")
	for other: int in enemies.keys():
		if other != id and not enemies[other].terminal:
			enemies[other].rig.queue_free()
			enemies.erase(other)
	_board.queue_redraw()

func _heat_overflow() -> void:
	for actor: Actor in enemies.values():
		if actor.enemy.definition.heat_per_second > 0.0:
			_effect("heat_overflow", actor.enemy.grid_position(), 34)

func _facility_action(unit: DeploymentState.Placement, at: Vector2, cue: String) -> void:
	var turret: Turret = turrets.get(unit.id)
	if turret != null:
		_play_turret(turret, &"Active")
		_effect(cue, at, 24)

func _repaired(unit: DeploymentState.Placement, target: Vector2i) -> void:
	if rangers.has(unit.id):
		_play(rangers[unit.id], &"Attack")
		_socket_effect(rangers[unit.id], "repair", Vector2(unit.anchor), "attack_fx", 20)
	_effect("repair", Vector2(target), 24)

func _deploy_turret(unit: DeploymentState.Placement, scene: PackedScene) -> void:
	var turret := Turret.new()
	turret.unit = unit
	turret.rig = scene.instantiate()
	if full_pack:
		var layout := _assets.facility_layout(unit.spec.id)
		if not layout.is_empty():
			turret.anchor = FirstContactSkin.vector(layout.anchor)
	turret.rig.hide()
	turret.player = turret.rig.get_node("AnimationPlayer")
	turret.player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(turret.rig)
	for part: Sprite2D in turret.rig.find_children("*", "Sprite2D", true, false):
		turret.parts.append(part)
	turret.parts.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool: return a.z_index < b.z_index)
	turrets[unit.id] = turret
	var state := &"Ready" if full_pack and _battle.deployment.build_ticks_left(unit.id) == 0 else &"Construction"
	_play_turret(turret, state)

func _play_turret(turret: Turret, clip: StringName) -> void:
	turret.clip = clip
	turret.phase = 0.0
	turret.player.play(clip)
	turret.player.advance(0.0)

func _turret_attack(unit: DeploymentState.Placement) -> void:
	var turret: Turret = turrets.get(unit.id)
	if turret != null:
		_play_turret(turret, &"Active")
		_effect("sonic", Vector2(unit.anchor) + TURRET_SOCKET / 80.0 - Vector2.ONE * 0.5, 22)

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
	for id: StringName in turrets.keys():
		var turret := turrets[id]
		turret.phase += seconds
		turret.player.advance(seconds)
		var finished := turret.phase >= turret.player.get_animation(turret.clip).length
		if turret.clip == &"Destroyed":
			if finished:
				turret.rig.queue_free()
				turrets.erase(id)
			continue
		var building := _battle.deployment.build_ticks_left(id) > 0
		if finished or (not building and turret.clip == &"Construction"):
			var current := &"Construction" if building else _facility_rest_state(turret)
			if turret.clip != current:
				_play_turret(turret, current)
	for i in range(_effects.size() - 1, -1, -1):
		var effect := _effects[i]
		if tick >= effect.expires or (effect.actor != null and not is_instance_valid(effect.actor.rig)):
			_effects.remove_at(i)
	_board.queue_redraw()

func _facility_rest_state(turret: Turret) -> StringName:
	if not full_pack:
		return &"Ready"
	match turret.unit.facility.role:
		FacilitySpec.Role.SENTRY_TOWER:
			if not turret.unit.mounted_ranger.is_empty():
				return &"Active"
			for enemy: BattleEnemy in _battle.active.values():
				if enemy.tower_detected:
					var delta := (enemy.grid_cell() - turret.unit.anchor).abs()
					if maxi(delta.x, delta.y) <= turret.unit.facility.detection_radius:
						return &"Active"
		FacilitySpec.Role.FIREBREAK:
			if _battle.heat > 0.0:
				return &"Active"
	return &"Ready"

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
	if full_pack and actor.enemy != null:
		idle = _enemy_motion(actor.enemy)
	if actor.enemy != null and actor.enemy.definition.enemy_id == FirstContactSkin.RUNNER \
			and actor.enemy.sprint_scale(_battle.clock.tick) > 1.0:
		idle = &"Sprint"
	var hold := &"Block" if actor.unit != null else &"Blocked"
	var next := hold if blocked else idle
	if not player.has_animation(next):
		next = idle
	if actor.clip != next and (actor.clip in [&"Move", &"Sprint", &"Idle", &"Conceal", &"Windup", &"Heat", hold] or actor.phase >= player.get_animation(actor.clip).length):
		if actor.unit != null and next == &"Block" and actor.unit.spec.id == &"ranger.patrolman":
			var effect := _effect("patrol_block", Vector2(actor.unit.anchor), 14)
			var socket: Array = _patrolman_sockets.block_contact_fx
			effect.actor = actor
			effect.socket = StringName(socket[0])
			effect.socket_offset = FirstContactSkin.vector(socket[1])
		_play(actor, next)
	return false

func _enemy_motion(enemy: BattleEnemy) -> StringName:
	match enemy.definition.enemy_id:
		&"E06":
			if not enemy.is_targetable(_battle.clock.tick):
				return &"Conceal"
		&"E11", &"E12":
			if not enemy.aim_target.is_empty():
				return &"Windup"
		&"E14":
			return &"Heat"
	return &"Move"

func draw_ground() -> void:
	if _regional != null:
		_regional.draw_ground()
		return
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

func draw_siege_warning(center: Vector2) -> void:
	_fx("siege", center + Vector2(0, _board.tile_size() * 0.20), 0.36)

func draw_slow_field(rect: Rect2) -> void:
	var texture := _assets.effect("slow_field")
	if texture != null:
		_board.draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.65))
	else:
		_board.draw_rect(rect, Color(0.18, 0.73, 0.66, 0.38))

func draw_facility_preview(spec: DeploymentSpec, cell: Vector2i) -> void:
	if not full_pack:
		if spec.logistics_post:
			draw_post(_center(Vector2(cell) + Vector2(0.5, 0)), Color(1, 1, 1, 0.52))
		return
	var layout := _assets.facility_layout(spec.id)
	if layout.is_empty():
		return
	var scale_px: float = _board.tile_size() / 80.0
	var origin := _tile(cell).position + FirstContactSkin.vector(layout.anchor) * scale_px
	for part: Array in layout.ghost.parts:
		var texture := _assets.texture(part[0])
		if texture != null:
			var rect := Rect2(origin + FirstContactSkin.vector(part[1]) * scale_px,
				FirstContactSkin.vector(part[2]) * scale_px)
			_board.draw_texture_rect(texture, rect, false, Color(1, 1, 1, layout.ghost.opacity))

func draw_turrets() -> void:
	var scale_px: float = _board.tile_size()
	var local: Transform2D = _board.get_global_transform().affine_inverse()
	for turret: Turret in turrets.values():
		var unit := turret.unit
		turret.rig.position = _board.grid_origin() + (Vector2(unit.anchor) + turret.anchor / 80.0) * scale_px
		turret.rig.scale = Vector2.ONE * scale_px / 80.0
		for part: Sprite2D in turret.parts:
			if _part_visible(part, turret.rig):
				_board.draw_set_transform_matrix(local * part.global_transform)
				_board.draw_texture(part.texture, Vector2.ZERO, part.self_modulate)
		_board.draw_set_transform(Vector2.ZERO)
		if turret.clip != &"Destroyed":
			var footprint_center := float(unit.spec.footprint(unit.anchor).size() - 1) * 0.5
			var cell_center := _center(Vector2(unit.anchor) + Vector2(footprint_center, 0))
			var seconds := ceili(float(_battle.deployment.build_ticks_left(unit.id)) / CombatClock.TICKS_PER_SECOND)
			if seconds > 0:
				if full_pack:
					terrain("KRT_56", _tile(unit.anchor), Color(1, 1, 1, 0.45))
				_board._draw_unit_label(unit, cell_center, "Building · %ds" % seconds)
			if full_pack:
				for reserved: Vector2i in unit.spec.reserved(unit.anchor):
					if not _battle.deployment.placed.has(unit.mounted_ranger):
						terrain("KRT_55", _tile(reserved), Color(1, 1, 1, 0.52))
			_board._draw_health(cell_center + Vector2(0, scale_px * 0.4), scale_px * 0.8, unit.hp, unit.spec.max_hp)

func draw_actors() -> void:
	var scale_px: float = _board.tile_size()
	var drawn: Array[Actor] = []
	drawn.assign(rangers.values())
	drawn.append_array(enemies.values())
	# Escape switches to Exit inside the dense canopy. Its final pose keeps
	# sampling offscreen without bleeding through transparent gaps in the leaves.
	drawn = drawn.filter(func(actor: Actor) -> bool: return not actor.escaped)
	var stacked: Dictionary[StringName, int] = {}
	for actor: Actor in drawn:
		if not is_instance_valid(actor.rig) or actor.rig.is_queued_for_deletion():
			continue
		var anchor := Vector2(actor.unit.anchor) if actor.unit != null else actor.enemy.grid_position()
		var offset := _block_offset(actor.enemy, stacked) if actor.enemy != null and not actor.terminal else 0.0
		actor.rig.position = _center(anchor) + Vector2(0, (_foot_offset(actor) + offset) * scale_px)
		actor.rig.scale = Vector2.ONE * scale_px / 80.0
	drawn.sort_custom(func(a: Actor, b: Actor) -> bool: return a.rig.position.y < b.rig.position.y)
	var local: Transform2D = _board.get_global_transform().affine_inverse()
	for actor: Actor in drawn:
		if not is_instance_valid(actor.rig) or actor.rig.is_queued_for_deletion():
			continue
		var alpha := 1.0
		if full_pack and actor.enemy != null and not actor.enemy.is_targetable(_battle.clock.tick):
			alpha = 0.5
		if actor.terminal and actor.clip != &"Captured":
			alpha = 1.0 - clampf(actor.phase / actor.rig.player.get_animation(actor.clip).length, 0.0, 1.0)
		for part: Sprite2D in actor.parts:
			if not full_pack or _part_visible(part, actor.rig):
				_board.draw_set_transform_matrix(local * part.global_transform)
				_board.draw_texture(part.texture, Vector2.ZERO, Color(1, 1, 1, alpha) * part.self_modulate)
		_board.draw_set_transform(Vector2.ZERO)
		if not actor.terminal:
			var hp := actor.unit.hp if actor.unit != null else actor.enemy.hp
			var maximum := actor.unit.spec.max_hp if actor.unit != null else actor.enemy.definition.max_hp
			_board._draw_health(actor.rig.position + Vector2(0, scale_px * 0.055), scale_px * 0.48, hp, maximum)
			if actor.enemy != null:
				_board._draw_enemy_status(actor.enemy, actor.rig.position - Vector2(0, scale_px * 0.32), scale_px)
			if full_pack:
				_draw_status_art(actor, scale_px)
	for id: int in _battle.active:
		if not enemies.has(id):
			var enemy := _battle.active[id]
			var at := _center(enemy.grid_position()) + Vector2(0, _block_offset(enemy, stacked) * scale_px)
			_board.draw_enemy_marker(enemy, at, scale_px, true)
	_draw_effects()
	if _regional != null:
		_regional.draw_foreground()
	else:
		_woodland(2)

func _part_visible(part: Node2D, root: Node2D) -> bool:
	var node := part
	while node != root:
		if not node.visible:
			return false
		node = node.get_parent() as Node2D
	return true

func _draw_status_art(actor: Actor, scale_px: float) -> void:
	var tick := _battle.clock.tick
	var cues: Array[String] = []
	if actor.enemy != null:
		var enemy := actor.enemy
		if enemy.definition.concealed or enemy.smoke_until > tick:
			cues.append("detected" if enemy.is_targetable(tick) else "concealed")
		if enemy.is_marked(tick):
			cues.append("marked")
		if enemy.stunned_until > tick:
			cues.append("stunned")
		elif enemy.immobilized_until > tick:
			cues.append("snared")
		if enemy.definition.heat_per_second + enemy.phase_heat_bonus > 0:
			_fx("heat_smoke", actor.rig.position - Vector2(0, scale_px * 0.70), 0.54)
	else:
		var unit := actor.unit
		if unit.jammed_until > tick:
			cues.append("emp")
		if unit.entangled_until > tick:
			cues.append("snared")
		if unit.knocked_down_until > tick:
			cues.append("knockdown")
	for index in cues.size():
		_fx(cues[index], actor.rig.position + Vector2(scale_px * (0.28 + index * 0.15), -scale_px * 0.54), 0.19)

func _block_offset(enemy: BattleEnemy, stacked: Dictionary[StringName, int]) -> float:
	if enemy.blocked_by.is_empty():
		return 0.0
	var slot: int = stacked.get(enemy.blocked_by, 0)
	stacked[enemy.blocked_by] = slot + 1
	return -0.19 if slot == 0 else 0.19

func _foot_offset(actor: Actor) -> float:
	if actor.unit == null or actor.unit.mount_tower.is_empty():
		return ACTOR_FOOT_OFFSET
	var tower: Turret = turrets.get(actor.unit.mount_tower)
	if full_pack and tower != null:
		var mount := tower.rig.get_node_or_null("MountSocket") as Marker2D
		if mount != null:
			return (tower.anchor.y + mount.position.y) / 80.0 + 0.5
	return ACTOR_FOOT_OFFSET - TOWER_LIFT

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
		elif effect.name == "poacher_strike":
			if elapsed >= 4:
				_fx("enemy_hit", at, 0.28)
		elif effect.name == "treatment":
			_paint_healing(at, 0.30)
			_paint_healing(_center(effect.target) - Vector2(0, _board.tile_size() * 0.22), 0.44)
		elif effect.name == "sonic":
			var progress := float(elapsed) / (effect.expires - effect.start)
			_board.draw_arc(at, _board.tile_size() * lerpf(0.13, 0.85, progress), 0.0, TAU, 24,
				Color(0.66, 0.9, 0.85, 1.0 - progress), 2.0, true)
		elif effect.name != "patrol_strike" or elapsed >= 8:
			_fx(effect.name, at, 0.38)

func _paint_healing(center: Vector2, width: float) -> void:
	var extent: Vector2 = HEAL.get_size() * (_board.tile_size() * width / HEAL.get_width())
	_board.draw_texture_rect(HEAL, Rect2(center - extent * 0.5, extent), false)

func _fx(id: String, center: Vector2, width: float, turn := 0.0) -> void:
	var texture := _assets.effect(id) if full_pack else null
	if texture == null:
		texture = _skin.try_region("effects", id)
	if texture == null:
		return
	var extent: Vector2 = texture.get_size() * (_board.tile_size() * width / texture.get_width())
	_board.draw_set_transform(center, turn)
	_board.draw_texture_rect(texture, Rect2(-extent * 0.5, extent), false)
	_board.draw_set_transform(Vector2.ZERO)
