class_name StoryPortrait
extends Control

const GESTURE := {
	"briefing": Vector2(64, 2), "concerned": Vector2(21, 13), "relieved": Vector2(4, 35),
	"steady": Vector2(45, 46), "reassuring": Vector2(55, 14), "alert": Vector2(28, -25),
	"confronting": Vector2(71, 4), "captured": Vector2(-9, 48),
}

const FIRST_CONTACT := {
	"portrait.manager": {
		"briefing": preload("res://assets/imported/first_contact/manager_briefing.png"),
		"relieved": preload("res://assets/imported/first_contact/manager_relieved.png"),
	},
	"portrait.leader": {"steady": preload("res://assets/imported/first_contact/leader_radio.png")},
}
const MESSENGER_PORTRAIT := preload("res://assets/imported/portraits/poacher/alert.png")
const MESSENGER_CUE := preload("res://assets/imported/portraits/story/messenger_cue.png")
var illustrated := false
var messenger_alert := false
var assets: CampaignVisualAssets
var _texture: Texture2D

var identity := ""
var pose := ""
var _settle := 0.0
var _motion: Tween

func present(key: String, expression: String, messenger := false) -> void:
	identity = key
	pose = expression
	messenger_alert = messenger
	_texture = null
	if illustrated:
		var variants: Dictionary = FIRST_CONTACT.get(identity, {})
		if not variants.is_empty():
			var alias := {"concerned": "briefing", "reassuring": "steady"}
			_texture = variants.get(pose, variants.get(alias.get(pose, "")))
		elif assets != null:
			_texture = assets.portrait(identity, pose)
	if _motion != null:
		_motion.kill()
	queue_redraw()
	if _texture != null or (illustrated and messenger_alert):
		return
	_settle = -5.0
	_motion = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion.tween_method(_settle_pose, -5.0, 0.0, 0.18)

func _settle_pose(offset: float) -> void:
	_settle = offset
	queue_redraw()

# Labelled storyboard stand-in. Silhouette, head angle and brows follow the speaker and pose.
func _draw() -> void:
	if illustrated and messenger_alert:
		var extent := minf(size.x * 0.66, size.y)
		var origin := Vector2((size.x - extent) * 0.5, size.y - extent)
		draw_texture_rect(MESSENGER_PORTRAIT, Rect2(origin, Vector2.ONE * extent), false)
		draw_texture_rect(MESSENGER_CUE, Rect2(origin + Vector2(0.79, 0.29) * extent, Vector2.ONE * extent * 0.39), false)
		return
	if _texture != null:
		var fit := minf(size.x / _texture.get_width(), size.y / _texture.get_height())
		var extent := _texture.get_size() * fit
		draw_texture_rect(_texture, Rect2(Vector2((size.x - extent.x) * 0.5, size.y - extent.y), extent), false)
		return
	var center := size * 0.5 + Vector2(0, _settle)
	var lean := -0.12 if pose in ["concerned", "captured"] else (0.10 if pose in ["alert", "confronting"] else 0.0)
	draw_set_transform(center, lean, Vector2.ONE * minf(1.55, size.y / 124.0))
	var uniform := Color("#77926f") if identity in ["portrait.leader", "portrait.manager"] else Color("#ab7759")
	draw_colored_polygon(PackedVector2Array([Vector2(-67,60),Vector2(-48,30),Vector2(-22,19),Vector2(22,19),Vector2(48,30),Vector2(67,60)]), uniform)
	if identity != "portrait.leader":
		draw_circle(Vector2(0,-8), 35, StoryUI.BEIGE)
	match identity:
		"portrait.leader":
			draw_colored_polygon(PackedVector2Array([Vector2(-42, 9), Vector2(-43, -22), Vector2(-26, -47), Vector2(11, -51), Vector2(38, -28), Vector2(39, 3), Vector2(19, 26), Vector2(-20, 25)]), Color("#8C8D5E"))
			draw_colored_polygon(PackedVector2Array([Vector2(-28, 3), Vector2(-26, -19), Vector2(-9, -33), Vector2(17, -35), Vector2(28, -21), Vector2(26, 2), Vector2(14, 18), Vector2(-13, 16)]), StoryUI.INK)
		"portrait.manager":
			draw_rect(Rect2(-38,-44,76,13), uniform)
			draw_circle(Vector2(32,-7), 8, StoryUI.INK)
			draw_line(Vector2(32,-7), Vector2(19,10), StoryUI.INK, 3)
		"portrait.illegal_logging_foreman":
			draw_arc(Vector2(0,-25), 34, PI, TAU, 24, StoryUI.AMBER, 12)
			draw_rect(Rect2(-41,-30,82,9), StoryUI.AMBER)
		"portrait.diversion_captain":
			draw_colored_polygon(PackedVector2Array([Vector2(-36,-25),Vector2(-24,-52),Vector2(37,-38),Vector2(26,-25)]), StoryUI.INK)
		"portrait.poacher_leader":
			draw_line(Vector2(-48,41), Vector2(29,25), StoryUI.AMBER, 9)
		_:
			draw_rect(Rect2(-41,-42,80,13), uniform)
	var hand: Vector2 = GESTURE.get(pose, Vector2(42, 44))
	draw_line(Vector2(36, 42), hand, uniform.darkened(0.25), 12, true)
	draw_circle(hand, 7, StoryUI.BEIGE)
	if identity != "portrait.leader":
		for side: int in [-1, 1]:
			draw_circle(Vector2(side * 13,-8), 3.5, StoryUI.INK)
			draw_line(Vector2(side * 6,-15), Vector2(side * 21,-17 - lean * 35), StoryUI.INK, 3)
