class_name CampaignHeatDisplay
extends RefCounted

# The shipped W29 scene supplies the track, fill and icon. The existing
# gauge and label remain the live sources for capacity and amount.
static func apply(row: Control, gauge: ProgressBar, sample: PackedScene) -> void:
	if sample == null:
		return
	var template := sample.instantiate()
	var styled: TextureProgressBar = template.get_node("%HeatGauge")
	var icon := TextureRect.new()
	icon.texture = template.get_node("Flame").texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size.x = 26
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	row.move_child(icon, 0)
	var track := StyleBoxTexture.new()
	track.texture = styled.texture_under
	var fill := StyleBoxTexture.new()
	fill.texture = styled.texture_progress
	gauge.add_theme_stylebox_override("background", track)
	gauge.add_theme_stylebox_override("fill", fill)
	template.free()
