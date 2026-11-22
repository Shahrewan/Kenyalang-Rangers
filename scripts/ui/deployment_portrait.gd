extends Control

const SCOUT_HEAD := preload("res://assets/imported/rangers/scout_sniper/head.png")
const SCOUT_HAT := preload("res://assets/imported/rangers/scout_sniper/hat.png")

var spec: DeploymentSpec

func _draw() -> void:
	var at := size * 0.5
	draw_circle(at, 21.0, Color("#566449"), true, -1, true)
	if spec.id == &"scout":
		var origin := at - Vector2(19, 15)
		draw_texture_rect(SCOUT_HEAD, Rect2(origin + Vector2(4.2, 7.1), SCOUT_HEAD.get_size() * 0.16), false)
		draw_texture_rect(SCOUT_HAT, Rect2(origin, SCOUT_HAT.get_size() * 0.16), false)
	elif spec.is_ranger():
		draw_colored_polygon(PackedVector2Array([
			at + Vector2(-15, 13), at + Vector2(-11, 7), at + Vector2(11, 7), at + Vector2(15, 13),
		]), Color("#BB9D73"))
		draw_circle(at + Vector2(0, -3), 10, Color("#F3EBDD"), true, -1, true)
		draw_rect(Rect2(at + Vector2(-13, -11), Vector2(26, 6)), Color("#E8B957"))
	else:
		draw_rect(Rect2(at + Vector2(-12, -9), Vector2(24, 18)), Color("#E8B957"))
		draw_rect(Rect2(at + Vector2(-8, -5), Vector2(16, 10)), Color("#343D32"), false, 2)
