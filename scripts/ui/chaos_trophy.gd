class_name ChaosTrophy
extends VBoxContainer

var personal_best := 0
var show_thresholds := false

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var tier := ChaosScore.tier(personal_best)
	var summary := StoryUI.row(self, 8)
	var emblem := artwork(tier, 82)
	emblem.name = "TrophyTier%d" % tier
	emblem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	summary.add_child(emblem)
	var details := StoryUI.column(summary, 4)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var best := StoryUI.label("Personal best · %s" % StoryUI.funds(personal_best), 23)
	best.name = "ChaosPersonalBest"
	details.add_child(best)
	details.add_child(StoryUI.label("Tier %d" % tier if tier > 0 else "Unranked", 19, StoryUI.AMBER))
	if show_thresholds:
		var assets := CampaignVisualAssets.new()
		for facility in ChaosScore.tier_facilities():
			var row := StoryUI.row(self, 6)
			row.add_child(StoryUI.artwork(assets.badge(facility.id), Vector2(27, 27)))
			var text := "%s · %s" % [StoryUI.funds(facility.chaos_threshold), facility.label]
			if personal_best >= facility.chaos_threshold:
				text += " · Earned"
			var label := StoryUI.label(text, 17, StoryUI.BEIGE)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(label)

static func artwork(tier: int, side: int) -> Control:
	var layers := Control.new()
	layers.custom_minimum_size = Vector2.ONE * side
	layers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tier > 0:
		_add_layer(layers, "tier_%d.png" % (tier * 1000), "Emblem")
	_add_layer(layers, "mount.png", "Mount")
	return layers

static func _add_layer(layers: Control, file: String, id: String) -> void:
	var texture := HeadquartersArt.resource(HeadquartersArt.TROPHIES + file, "Texture2D") as Texture2D
	var image := StoryUI.artwork(texture, Vector2.ZERO)
	image.name = id
	layers.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
