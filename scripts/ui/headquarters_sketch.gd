extends Control

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var origin := size * 0.5
	var factor := minf(size.x / 560.0, size.y / 310.0)
	draw_set_transform(origin, 0.0, Vector2.ONE * factor)
	draw_rect(Rect2(-265, -140, 530, 280), Color("#DBD2B8"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-265, 65), Vector2(-122, -80), Vector2(-26, 25), Vector2(113, -92),
		Vector2(265, 72), Vector2(265, 138), Vector2(-265, 138),
	]), Color("#AAA983"))
	for at in [-228, -190, 186, 230]:
		var x := float(at)
		draw_rect(Rect2(x - 3, 61, 6, 45), Color("#62583E"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 31, 73), Vector2(x, 4), Vector2(x + 28, 73),
		]), Color("#69734A"))
	draw_rect(Rect2(-161, -45, 322, 149), Color("#B59067"))
	draw_rect(Rect2(-165, -54, 330, 12), Color("#343D32"))
	draw_rect(Rect2(-161, 44, 322, 6), Color("#343D32"))
	for index in 5:
		var x := -140.0 + index * 58
		draw_rect(Rect2(x, -23, 38, 44), Color("#694F43"))
		draw_rect(Rect2(x + 4, -19, 30, 36), Color("#C8C9A8"))
		draw_line(Vector2(x + 19, -19), Vector2(x + 19, 17), Color("#694F43"), 3.0)
	draw_rect(Rect2(-22, 59, 44, 45), Color("#343D32"))
	draw_rect(Rect2(-172, 104, 344, 8), Color("#656649"))
