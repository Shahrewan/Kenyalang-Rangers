class_name HeadquartersOfficeArt
extends Control

var role := HeadquartersRoom.Role.CONTROL
var built := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var scale_factor := Vector2(size.x / 240.0, size.y / 65.0)
	draw_set_transform(Vector2.ZERO, 0.0, scale_factor)
	draw_rect(Rect2(0, 0, 240, 65), Color("#c7bda5") if built else Color("#d5c9ac"))
	draw_rect(Rect2(0, 52, 240, 13), Color("#8b7759"))
	draw_rect(Rect2(148, 8, 65, 37), Color("#556457"))
	draw_rect(Rect2(152, 12, 57, 29), Color("#a9b9a0") if built else Color("#b4a589"))
	draw_line(Vector2(181, 12), Vector2(181, 41), Color("#556457"), 2.0)
	if not built:
		_desk(23, 30, Color("#9a744b"))
		draw_rect(Rect2(24, 34, 22, 4), Color("#bfab7d"))
		return
	match role:
		HeadquartersRoom.Role.ECOLOGY:
			for x in [37, 69, 101]:
				draw_rect(Rect2(x, 39, 14, 13), Color("#895738"))
				draw_circle(Vector2(x + 6, 31), 8, Color("#557f52"))
				draw_circle(Vector2(x + 13, 28), 6, Color("#799460"))
		HeadquartersRoom.Role.RECORDS, HeadquartersRoom.Role.HR:
			draw_rect(Rect2(28, 9, 72, 43), Color("#7e654c"))
			for i in 6:
				draw_rect(Rect2(33 + i * 10, 16, 7, 30 - i % 3 * 3), Color("#d9be7c") if i % 2 == 0 else Color("#86a294"))
		_:
			_desk(29, 37, Color("#98744e"))
			draw_rect(Rect2(48, 16, 50, 23), Color("#465b50"))
			draw_rect(Rect2(51, 19, 44, 16), Color("#87a697"))
			draw_rect(Rect2(70, 39, 6, 6), Color("#465b50"))

func _desk(x: int, y: int, color: Color) -> void:
	draw_rect(Rect2(x, y + 12, 98, 6), color)
	draw_rect(Rect2(x + 3, y + 17, 8, 9), color)
	draw_rect(Rect2(x + 85, y + 17, 8, 9), color)
