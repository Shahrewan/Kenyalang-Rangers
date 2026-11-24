extends HBoxContainer

@onready var _wave: Label = %WaveCount
@onready var _defeated: Label = %DefeatedCount
@onready var _integrity: Label = %IntegrityCount
@onready var _tokens: Label = %TokenCount

func render(battle: BattleSimulation, total: int, tokens: int) -> void:
	_wave.text = "Wave %d/%d" % [battle.wave_number, battle.wave_count]
	_defeated.text = "Defeated %d/%d" % [battle.defeated, total]
	_integrity.text = "Integrity %d" % battle.integrity
	_tokens.text = "%d Tokens" % tokens

var _illustrated_panel: StyleBoxTexture

func illustrate(skin: FirstContactSkin) -> void:
	_illustrated_panel = skin.panel("battle_hud")
	skin.button(%Pause, "button_secondary")
	skin.button(%Speed, "button_secondary")
	for row: Array in [[_wave, "wave"], [_integrity, "integrity"]]:
		var label: Label = row[0]
		var icon := TextureRect.new()
		icon.texture = skin.region("interface", row[1])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size.x = 24
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)
		move_child(icon, label.get_index())
		label.add_theme_color_override("font_color", StoryUI.CREAM)
	$Tokens/Icon.hide()
	var token := TextureRect.new()
	token.texture = skin.region("interface", "token")
	token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	token.custom_minimum_size.x = 25
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Tokens.add_child(token)
	$Tokens.move_child(token, 0)
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if _illustrated_panel != null:
		draw_style_box(_illustrated_panel, Rect2(Vector2.ZERO, size))
