extends Control

@onready var rig: ScoutRig = %Scout
@onready var stage: Control = %Stage
var clock := CombatClock.new()
var _direction := 1

func _ready() -> void:
	clock.stepped.connect(_step)
	for clip in ScoutRig.CLIPS:
		var button := Button.new()
		button.text = clip
		button.custom_minimum_size = Vector2(104, 54)
		button.pressed.connect(rig.play_state.bind(clip))
		%Clips.add_child(button)
	%Pause.pressed.connect(_pause)
	%Speed.pressed.connect(_speed)
	%Flip.pressed.connect(_flip)
	%Lock.toggled.connect(func(enabled: bool) -> void:
		rig.facing_locked = enabled
		%Flip.disabled = enabled
	)
	stage.resized.connect(_layout)
	stage.draw.connect(_draw_stage)
	_layout()

func _physics_process(_delta: float) -> void:
	clock.advance_frame()

func _step(_tick: int, seconds: float) -> void:
	rig.advance_combat(seconds)

func _layout() -> void:
	rig.position = stage.size * 0.5 + Vector2(0, 36)
	stage.queue_redraw()

func _draw_stage() -> void:
	var origin := stage.size * 0.5 - Vector2(200, 34)
	for index in 5:
		var tile := Rect2(origin + Vector2(index * 80, 0), Vector2(80, 80)).grow(-2)
		stage.draw_rect(tile, Color("#69734A") if index == 2 else Color("#BB9D73"))
	var baseline := rig.position + Vector2(-20, 7)
	stage.draw_rect(Rect2(baseline, Vector2(40, 4)), Color("#B8D68A"))

func _pause() -> void:
	clock.paused = not clock.paused
	%Pause.text = "Resume" if clock.paused else "Pause"

func _speed() -> void:
	clock.set_speed(3 - clock.get_speed())
	%Speed.text = "%d×" % clock.get_speed()

func _flip() -> void:
	_direction *= -1
	rig.set_facing(_direction)
