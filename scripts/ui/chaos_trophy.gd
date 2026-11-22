class_name ChaosTrophy
extends HBoxContainer

var personal_best := 0
var show_thresholds := false

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var tier := ChaosScore.tier(personal_best)
	var emblem := TrophyArt.new()
	emblem.tier = tier
	emblem.name = "TrophyTier%d" % tier
	emblem.custom_minimum_size = Vector2(94, 104)
	emblem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(emblem)
	var details := StoryUI.column(self, 4)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var best := StoryUI.label("Personal best · %s" % StoryUI.funds(personal_best), 23)
	best.name = "ChaosPersonalBest"
	details.add_child(best)
	details.add_child(StoryUI.label("Tier %d" % tier if tier > 0 else "Unranked", 19, StoryUI.AMBER))
	details.add_child(StoryUI.label("Placeholder trophy art", 15, StoryUI.BEIGE))
	if show_thresholds:
		for facility in ChaosScore.tier_facilities():
			var text := "%s · %s" % [StoryUI.funds(facility.chaos_threshold), facility.label]
			if personal_best >= facility.chaos_threshold:
				text += " · Earned"
			details.add_child(StoryUI.label(text, 17, StoryUI.BEIGE))

class TrophyArt extends Control:
	var tier := 0

	func _draw() -> void:
		var center := size / 2.0
		var shine := Color("#c5af83")
		draw_rect(Rect2(center + Vector2(-34, 33), Vector2(68, 12)), Color("#5a4c3a"))
		draw_rect(Rect2(center + Vector2(-31, 34), Vector2(62, 3)), shine)
		if tier == 0:
			draw_line(center + Vector2(-17, 28), center + Vector2(17, 28), Color("#8c8067"), 2.0, true)
			return
		var metal := [Color("#ae744b"), Color("#afc0bd"), Color("#dfab47")][tier - 1] as Color
		draw_rect(Rect2(center + Vector2(-6, 5), Vector2(12, 29)), metal.darkened(0.20))
		if tier == 1:
			draw_circle(center + Vector2(0, -9), 23, metal, true, -1, true)
			draw_circle(center + Vector2(0, -9), 16, metal.lightened(0.28), false, 3.0, true)
		else:
			var cup := PackedVector2Array([center + Vector2(-22, -33), center + Vector2(22, -33), center + Vector2(16, 0), center + Vector2(0, 12), center + Vector2(-16, 0)])
			draw_arc(center + Vector2(-21, -16), 12, PI / 2.0, PI * 1.5, 16, metal.darkened(0.22), 4, true)
			draw_arc(center + Vector2(21, -16), 12, -PI / 2.0, PI / 2.0, 16, metal.darkened(0.22), 4, true)
			draw_colored_polygon(cup, metal)
			draw_line(center + Vector2(-20, -30), center + Vector2(20, -30), metal.lightened(0.42), 4, true)
			if tier == 3:
				for x in [-12, 0, 12]:
					draw_circle(center + Vector2(x, -14), 3.5, Color("#fff0bb"), true, -1, true)
