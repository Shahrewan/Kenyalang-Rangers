extends Control

const MAIN_MENU := preload("res://scenes/menus/main_menu.tscn")
const FIRST_CONTACT := preload("res://data/stages/c05_first_contact.tres")
const SAMPLE_BATTLE := preload("res://scenes/battle/sample_battle.tscn")

@onready var _content: Control = %ScreenContent

var _screen: Control

func _ready() -> void:
	show_menu()

func show_menu() -> void:
	_show_screen(MAIN_MENU)
	var open_sample: Button = _screen.get_node("%OpenSample")
	open_sample.pressed.connect(show_sample)
	var first_contact: Button = _screen.get_node("%OpenCampaign")
	first_contact.pressed.connect(show_first_contact)
	first_contact.grab_focus()

func show_sample() -> void:
	_show_screen(SAMPLE_BATTLE)
	var back: Button = _screen.get_node("%BackToMenu")
	back.pressed.connect(show_menu)
	back.grab_focus()

func show_first_contact() -> void:
	_show_screen(SAMPLE_BATTLE, true)
	var back: Button = _screen.get_node("%BackToMenu")
	back.pressed.connect(show_menu)

func _show_screen(scene: PackedScene, first_contact := false) -> void:
	if is_instance_valid(_screen):
		_content.remove_child(_screen)
		_screen.queue_free()
	_screen = scene.instantiate()
	if first_contact:
		var battle_screen := _screen as BattleScene
		battle_screen.campaign = true
		battle_screen.stage = FIRST_CONTACT
	_content.add_child(_screen)
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
