extends HBoxContainer

const WAVE := preload("res://assets/imported/ui/w29/icons/light/list.svg")
const INTEGRITY := preload("res://assets/imported/ui/w29/icons/light/defense.svg")
const TOKENS := preload("res://assets/imported/ui/w29/icons/light/finance.svg")

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
	for row: Array in [[_wave, WAVE], [_integrity, INTEGRITY]]:
		var label: Label = row[0]
		var icon := StoryUI.artwork(row[1], Vector2(24, 24))
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(icon)
		move_child(icon, label.get_index())
		label.add_theme_color_override("font_color", StoryUI.CREAM)
	$Tokens/Icon.hide()
	var token := StoryUI.artwork(TOKENS, Vector2(24, 24))
	token.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	$Tokens.add_child(token)
	$Tokens.move_child(token, 0)
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if _illustrated_panel != null:
		draw_style_box(_illustrated_panel, Rect2(Vector2.ZERO, size))
