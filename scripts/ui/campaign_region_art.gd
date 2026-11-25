class_name CampaignRegionArt
extends RefCounted

var _board: BattleBoard
var _skin: FirstContactSkin
var _assets: CampaignVisualAssets
var layout: Dictionary

func _init(board: BattleBoard, skin: FirstContactSkin, assets: CampaignVisualAssets) -> void:
	_board = board
	_skin = skin
	_assets = assets
	layout = assets.region(board.battle_map.map_id)

func draw_ground() -> void:
	var map := _board.battle_map
	var backdrop := _assets.texture(layout.backdrop.texture)
	if backdrop != null:
		var fits := _board.size / backdrop.get_size()
		var crop := _board.size / maxf(fits.x, fits.y)
		var anchor := FirstContactSkin.vector(layout.backdrop.cover_anchor)
		_board.draw_texture_rect_region(backdrop, Rect2(Vector2.ZERO, _board.size),
			Rect2((backdrop.get_size() - crop) * anchor, crop))
	var cell := _board.tile_size()
	for row: Dictionary in layout.ground:
		var at := Vector2i(FirstContactSkin.vector(row.cell))
		if map.tile_at(at) != BattleMap.Tile.GROUND:
			continue
		var texture: Texture2D
		if row.region == "junction_04":
			# This junction is a separate W29 import outside the shared atlas.
			texture = _assets.texture(layout.atlas.junction_override.texture)
		else:
			texture = _skin.region("terrain", row.region)
		_turn(texture, at, deg_to_rad(row.clockwise_degrees), cell)
		_turn(_skin.region("terrain", "route_arrow"), at,
			FirstContactSkin.vector(row.arrow_direction).angle(), cell * 0.32)
	for row: Dictionary in layout.raised:
		var at := Vector2i(FirstContactSkin.vector(row.cell))
		if map.tile_at(at) == BattleMap.Tile.ELEVATED:
			var rect := _tile(at)
			_board.draw_texture_rect(_skin.region("terrain", row.region), rect, false)
			for edge: String in row.exposed_edge_art:
				_board.draw_texture_rect(_skin.region("terrain", edge), rect, false)
	var forecast: Array[Vector2i] = []
	if _board.battle != null:
		forecast = _board.battle.recon_entries()
	for gate: Dictionary in layout.entries:
		var at := Vector2i(FirstContactSkin.vector(gate.cell))
		if at not in map.spawns:
			continue
		_turn(_assets.texture(gate.texture), at, FirstContactSkin.vector(gate.outgoing).angle(), cell)
		if at in forecast:
			_board.draw_rect(_tile(at).grow(-2.0), Color("#e8b957"), false, 3.0)
			var marker := _assets.effect("entry_recon")
			if marker != null:
				_board.draw_texture_rect(marker, Rect2(_board.cell_center(at) - Vector2.ONE * cell * 0.44,
					Vector2.ONE * cell * 0.33), false)
	_board.draw_texture_rect(_skin.region("terrain", layout.exit.region), _tile(map.tunnel), false)
	_woodland("ground")
	_woodland("behind_actors")

func draw_foreground() -> void:
	_woodland("in_front_of_actors")

func _turn(texture: Texture2D, at: Vector2i, angle: float, extent: float) -> void:
	if texture == null:
		return
	_board.draw_set_transform(_board.cell_center(at), angle)
	_board.draw_texture_rect(texture, Rect2(Vector2.ONE * -extent * 0.5, Vector2.ONE * extent), false)
	_board.draw_set_transform(Vector2.ZERO)

func _tile(at: Vector2i) -> Rect2:
	var side := Vector2.ONE * _board.tile_size()
	return Rect2(_board.cell_center(at) - side * 0.5, side)

func _woodland(phase: String) -> void:
	var scale_px := _board.tile_size() / 80.0
	var tile := _tile(_board.battle_map.tunnel)
	for layer: Dictionary in layout.exit.layers:
		if layer.draw_phase != phase:
			continue
		var texture := _assets.texture(layer.texture)
		if texture == null:
			continue
		var bounds := Rect2(tile.position + FirstContactSkin.vector(layer.offset_units_from_terminal_top_left) * scale_px,
			FirstContactSkin.vector(layer.display_size_units) * scale_px)
		var clipped := Rect2(Vector2.ZERO, _board.size).intersection(bounds)
		if clipped.has_area():
			var source_scale := texture.get_size() / bounds.size
			_board.draw_texture_rect_region(texture, clipped,
				Rect2((clipped.position - bounds.position) * source_scale, clipped.size * source_scale))
