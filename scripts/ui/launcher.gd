extends Control

const MAIN_MENU := preload("res://scenes/menus/main_menu.tscn")
const SAMPLE_BATTLE := preload("res://scenes/battle/sample_battle.tscn")

@onready var _content: Control = %ScreenContent

var _screen: Control

func _ready() -> void:
	show_menu()

func show_menu() -> void:
	_show_screen(MAIN_MENU)
	var open_sample: Button = _screen.get_node("%OpenSample")
	open_sample.pressed.connect(show_sample)
	open_sample.grab_focus()

func show_sample() -> void:
	_show_screen(SAMPLE_BATTLE)
	var back: Button = _screen.get_node("%BackToMenu")
	back.pressed.connect(show_menu)
	back.grab_focus()

func _show_screen(scene: PackedScene) -> void:
	if is_instance_valid(_screen):
		_content.remove_child(_screen)
		_screen.queue_free()
	_screen = scene.instantiate()
	_content.add_child(_screen)
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
