class_name BattleBoard
extends Control

var battle_map: BattleMap
var routes: Array[BattleRoute]
var battle: BattleSimulation
var show_combat_hp := false
var deployments: DeploymentState
var preview_spec: DeploymentSpec
var preview_cell := DeploymentState.NO_CELL
var preview_facing := -1

func tile_size() -> float:
	if battle_map == null:
		return 0.0
	var grid := Vector2(battle_map.size)
	return minf(80.0, minf(size.x / grid.x, size.y / grid.y))

func grid_origin() -> Vector2:
	return (size - Vector2(battle_map.size) * tile_size()) / 2.0

func cell_at(viewport_position: Vector2) -> Vector2i:
	var cell_size := tile_size()
	if cell_size <= 4.0:
		return DeploymentState.NO_CELL
	var local := get_global_transform_with_canvas().affine_inverse() * viewport_position
	var cell := Vector2i(((local - grid_origin()) / cell_size).floor())
	return cell if Rect2i(Vector2i.ZERO, battle_map.size).has_point(cell) else DeploymentState.NO_CELL

func cell_center(cell: Vector2i) -> Vector2:
	return grid_origin() + (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size()

func facing_at(viewport_position: Vector2) -> int:
	var local := get_global_transform_with_canvas().affine_inverse() * viewport_position
	return -1 if local.x < cell_center(cell_at(viewport_position)).x else 1

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	if battle_map == null:
		return
	var cell := tile_size()
	if cell <= 4.0:
		return
	var origin := grid_origin()
	for tile in battle_map.ground:
		var rect := Rect2(origin + Vector2(tile) * cell, Vector2.ONE * cell).grow(-2.0)
		draw_rect(rect, Color("#BB9D73"))
	for tile in battle_map.elevated:
		var rect := Rect2(origin + Vector2(tile) * cell, Vector2.ONE * cell).grow(-2.0)
		draw_rect(rect, Color("#69734A"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color("#AAB385"))
	for route in routes:
		for index in range(1, route.cells.size() - 1):
			var origin_tile := cell_center(route.cells[index])
			var direction := Vector2(route.cells[index + 1] - route.cells[index])
			var perpendicular := Vector2(-direction.y, direction.x)
			var tip := origin_tile + direction * cell * 0.13
			var back := origin_tile - direction * cell * 0.02
			var faint := Color("#887356")
			draw_line(back + perpendicular * cell * 0.06, tip, faint, 2.0, true)
			draw_line(tip, back - perpendicular * cell * 0.06, faint, 2.0, true)
	var forecast: Array[Vector2i] = []
	if battle != null:
		forecast = battle.recon_entries()
	for i in battle_map.spawns.size():
		var spawn := battle_map.spawns[i]
		var label := "Entry" if battle_map.spawns.size() == 1 else "Entry %s" % char(65 + i)
		_draw_gate(origin + Vector2(spawn) * cell, cell, label, Color("#894534"))
		if spawn in forecast:
			var edge := Rect2(origin + Vector2(spawn) * cell, Vector2.ONE * cell).grow(-2.0)
			draw_rect(edge, Color("#e8b957"), false, 3.0)
	var tunnel := origin + Vector2(battle_map.tunnel) * cell
	_draw_gate(tunnel, cell, "Tunnel", Color("#15241C"))
	for offset in [0.21, 0.50, 0.79]:
		draw_circle(tunnel + Vector2(offset, 0.20) * cell, cell * 0.17, Color("#69734A"))
	if battle != null:
		_draw_slow_fields()
	if deployments != null:
		_draw_deployments()
	if battle != null:
		_draw_siege_warnings()
		var stacked: Dictionary[StringName, int] = {}
		for enemy: BattleEnemy in battle.active.values():
			var center := origin + (enemy.grid_position() + Vector2(0.5, 0.5)) * cell
			if show_combat_hp and not enemy.blocked_by.is_empty():
				var slot: int = stacked.get(enemy.blocked_by, 0)
				center.y += (-0.20 if slot == 0 else 0.20) * cell
				stacked[enemy.blocked_by] = slot + 1
			var visible_alpha := 1.0 if enemy.is_targetable(battle.clock.tick) else 0.4
			draw_circle(center, cell * 0.18, Color("#8B3E2C", visible_alpha), true, -1, true)
			draw_circle(center, cell * 0.18, Color("#F3EBDD", visible_alpha), false, 2.0, true)
			_draw_enemy_status(enemy, center, cell)
			if show_combat_hp:
				_draw_health(center + Vector2(0, cell * 0.24), cell * 0.46, enemy.hp, enemy.definition.max_hp)

func _draw_slow_fields() -> void:
	var bounds := Rect2i(Vector2i.ZERO, battle_map.size)
	for field in battle.ranger_combat.fields:
		var area := bounds.intersection(field.area)
		for y in range(area.position.y, area.end.y):
			for x in range(area.position.x, area.end.x):
				var cell := Vector2i(x, y)
				if battle_map.tile_at(cell) != BattleMap.Tile.NONDEPLOYABLE:
					draw_rect(_tile_rect(cell), Color(0.18, 0.73, 0.66, 0.38))

func _draw_enemy_status(enemy: BattleEnemy, center: Vector2, cell: float) -> void:
	var tick := battle.clock.tick
	if enemy.is_marked(tick):
		draw_circle(center + Vector2(0, -cell * 0.27), cell * 0.05, Color("#F3D586"))
	if tick < enemy.stunned_until or tick < enemy.immobilized_until:
		var color := Color("#F3D586") if tick < enemy.stunned_until else Color("#A3DDEA")
		draw_circle(center, cell * 0.21, color, false, 3.0, true)
	elif tick < enemy.sonic_slow_until:
		draw_circle(center, cell * 0.21, Color("#6FB9A4"), false, 2.0, true)
	if tick < enemy.ability_fire_tick:
		draw_circle(center, cell * 0.26, Color("#E8B957"), false, 2.0, true)
	if enemy.active_shield(tick) > 0:
		draw_circle(center, cell * 0.26, Color("#A3DDEA"), false, 3.0, true)
	var tag := "?" if not enemy.is_targetable(tick) else ("A" if enemy.definition.aerial else ("T" if enemy.definition.technological else ""))
	if not tag.is_empty():
		var font := get_theme_default_font()
		var font_size := maxi(10, roundi(cell * 0.22))
		var width := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, center + Vector2(-width / 2.0, font_size / 3.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#F3EBDD"))

func _draw_siege_warnings() -> void:
	if deployments == null:
		return
	var warned: Dictionary[StringName, bool] = {}
	for enemy: BattleEnemy in battle.active.values():
		var profile := enemy.definition.attack_profile
		if profile == null or profile.kind != EnemyAttackProfile.Kind.SIEGE or warned.has(enemy.aim_target):
			continue
		var target: DeploymentState.Placement = deployments.placed.get(enemy.aim_target)
		if target == null or target != enemy.aim_placement:
			continue
		warned[enemy.aim_target] = true
		for cell in target.spec.footprint(target.anchor):
			draw_rect(_tile_rect(cell), Color("#F28D72"), false, 3.0)
		var center := cell_center(target.anchor)
		var font := get_theme_default_font()
		var size_px := maxi(11, roundi(tile_size() * 0.23))
		var width := font.get_string_size("Siege", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		draw_string(font, center + Vector2(-width * 0.5, -tile_size() * 0.23), "Siege", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, Color("#FFD0BB"))

func _draw_gate(at: Vector2, cell: float, label: String, color: Color) -> void:
	draw_rect(Rect2(at, Vector2.ONE * cell).grow(-2.0), color)
	var font := get_theme_default_font()
	var font_size := maxi(10, roundi(cell * 0.24))
	var left := (cell - font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) / 2.0
	var baseline := (cell + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	draw_string(font, at + Vector2(left, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)


func _draw_deployments() -> void:
	if preview_spec != null:
		var candidates := battle_map.ground if preview_spec.is_melee() else battle_map.elevated
		for cell in candidates:
			if deployments.placement_error(preview_spec, cell).is_empty():
				draw_rect(_tile_rect(cell).grow(-4.0), Color("#C9D99B"), false, 2.0)
	if preview_spec != null and preview_cell != DeploymentState.NO_CELL:
		var valid := deployments.placement_error(preview_spec, preview_cell).is_empty()
		var border := Color("#F3D586") if valid else Color("#FFAC91")
		for cell in deployments.coverage(preview_spec, preview_cell, preview_facing):
			draw_rect(_tile_rect(cell), Color(0.93, 0.73, 0.32, 0.26))
		for cell in preview_spec.footprint(preview_cell) + preview_spec.reserved(preview_cell):
			if Rect2i(Vector2i.ZERO, battle_map.size).has_point(cell):
				draw_rect(_tile_rect(cell), border, false, 3.0)
		if preview_spec.is_melee():
			_draw_direction(preview_cell, preview_facing, border)
	var armed: DeploymentState.Placement = deployments.placed.get(deployments.armed)
	if armed != null:
		for cell in deployments.coverage(armed.spec, armed.anchor, armed.facing):
			draw_rect(_tile_rect(cell), Color(0.55, 0.82, 0.88, 0.33))
		if deployments.pending_target != DeploymentState.NO_CELL:
			draw_rect(_tile_rect(deployments.pending_target), Color("#E8F9FF"), false, 4.0)
	for id: StringName in deployments.placed:
		var unit := deployments.placed[id]
		var remaining := deployments.build_ticks_left(id)
		var color := Color("#B28550") if remaining > 0 else Color("#245567")
		for cell in unit.spec.footprint(unit.anchor):
			var model := _tile_rect(cell).grow(-8.0)
			if not unit.mount_tower.is_empty():
				model = model.grow(-6.0)
				model.position.y -= tile_size() * 0.36
				color = Color("#4D7F73")
			draw_rect(model, color)
		if remaining > 0:
			var font := get_theme_default_font()
			var seconds := ceili(float(remaining) / CombatClock.TICKS_PER_SECOND)
			draw_string(font, cell_center(unit.anchor) + Vector2(-12, 6), "%ds" % seconds)
		for cell in unit.spec.reserved(unit.anchor):
			if unit.facility != null and remaining == 0:
				draw_rect(_tile_rect(cell).grow(-13.0), color)
			draw_rect(_tile_rect(cell), Color("#D3B681"), false, 2.0)
		if unit.spec.is_melee():
			_draw_direction(unit.anchor, unit.facing, Color("#F3EBDD"))
		if show_combat_hp:
			var center := cell_center(unit.anchor)
			if unit.spec.footprint(unit.anchor).size() == 2:
				center.x += tile_size() / 2.0
			if not unit.mount_tower.is_empty():
				center.y -= tile_size() * 0.44
			if unit.facility != null and remaining == 0:
				_draw_facility_label(unit, center)
			_draw_health(center + Vector2(0, tile_size() * 0.40), tile_size() * 0.5, unit.hp, unit.spec.max_hp)

func _draw_facility_label(unit: DeploymentState.Placement, center: Vector2) -> void:
	var font := get_theme_default_font()
	var area_width := tile_size() * unit.spec.footprint(unit.anchor).size() - 16.0
	var size_px := maxi(10, roundi(tile_size() * 0.21))
	var label := unit.spec.label
	var measured := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	if measured > area_width:
		size_px = maxi(9, floori(size_px * area_width / measured))
	draw_string(font, center + Vector2(-area_width / 2.0, size_px * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, area_width, size_px, Color("#F3EBDD"))

func _draw_health(center: Vector2, width: float, hp: int, maximum: int) -> void:
	var bar := Rect2(center - Vector2(width / 2.0, 0), Vector2(width, 4))
	draw_rect(bar, Color("#202825"))
	bar.size.x *= clampf(float(hp) / maximum, 0.0, 1.0)
	draw_rect(bar, Color("#C6DB87") if hp == maximum else Color("#E8B957"))

func _tile_rect(cell: Vector2i) -> Rect2:
	return Rect2(grid_origin() + Vector2(cell) * tile_size(), Vector2.ONE * tile_size()).grow(-3.0)

func _draw_direction(cell: Vector2i, facing: int, color: Color) -> void:
	var center := cell_center(cell)
	var tip := center + Vector2(facing * 10, 0)
	draw_line(center - Vector2(facing * 10, 0), tip, color, 3.0, true)
	draw_line(tip, tip - Vector2(facing * 7, 6), color, 3.0, true)
	draw_line(tip, tip - Vector2(facing * 7, -6), color, 3.0, true)
