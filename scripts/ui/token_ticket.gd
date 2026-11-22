extends Control

func _draw() -> void:
	var top := (size.y - 20.0) / 2.0
	draw_rect(Rect2(1, top, 24, 20), Color("#E8B957"))
	for slot in 3:
		draw_rect(Rect2(16, top + 3 + slot * 6, 2, 2), Color("#343D32"))
	draw_circle(Vector2(1, top + 10), 3, Color("#273429"))
	draw_circle(Vector2(25, top + 10), 3, Color("#273429"))
