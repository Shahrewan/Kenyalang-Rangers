class_name BattleBoard
extends Control

var battle_map: BattleMap
var battle: BattleSimulation
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
	for spawn in battle_map.spawns:
		_draw_gate(origin + Vector2(spawn) * cell, cell, "Entry", Color("#894534"))
	var tunnel := origin + Vector2(battle_map.tunnel) * cell
	_draw_gate(tunnel, cell, "Tunnel", Color("#15241C"))
	for offset in [0.21, 0.50, 0.79]:
		draw_circle(tunnel + Vector2(offset, 0.20) * cell, cell * 0.17, Color("#69734A"))
	if deployments != null:
		_draw_deployments()
	if battle != null:
		for enemy: BattleEnemy in battle.active.values():
			var center := origin + (enemy.grid_position() + Vector2(0.5, 0.5)) * cell
			draw_circle(center, cell * 0.18, Color("#8B3E2C"), true, -1, true)
			draw_circle(center, cell * 0.18, Color("#F3EBDD"), false, 2.0, true)

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
	for unit: DeploymentState.Placement in deployments.placed.values():
		for cell in unit.spec.footprint(unit.anchor):
			draw_rect(_tile_rect(cell).grow(-8.0), Color("#245567"))
		for cell in unit.spec.reserved(unit.anchor):
			draw_rect(_tile_rect(cell), Color("#D3B681"), false, 2.0)
		if unit.spec.is_melee():
			_draw_direction(unit.anchor, unit.facing, Color("#F3EBDD"))

func _tile_rect(cell: Vector2i) -> Rect2:
	return Rect2(grid_origin() + Vector2(cell) * tile_size(), Vector2.ONE * tile_size()).grow(-3.0)

func _draw_direction(cell: Vector2i, facing: int, color: Color) -> void:
	var center := cell_center(cell)
	var tip := center + Vector2(facing * 10, 0)
	draw_line(center - Vector2(facing * 10, 0), tip, color, 3.0, true)
	draw_line(tip, tip - Vector2(facing * 7, 6), color, 3.0, true)
	draw_line(tip, tip - Vector2(facing * 7, -6), color, 3.0, true)
