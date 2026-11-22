extends VBoxContainer

signal back_requested
signal operation_requested

var index: StoryIndex
var operation: StoryOperation
var progress: Dictionary
var control_level := 1

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	StoryUI.header(self, "Story Mode", func() -> void: back_requested.emit(), "%d Funds" % progress.funds)
	var body := StoryUI.row(self, 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list_panel := StoryUI.panel(body, true)
	list_panel.get_parent().custom_minimum_size.x = 400
	list_panel.add_child(StoryUI.label(operation.region, 28, StoryUI.INK))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(scroll)
	var list := StoryUI.column(scroll)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var visible_count := 0
	for i in index.nodes.size():
		var entry := index.nodes[i]
		if int(entry.control) > control_level:
			continue
		visible_count += 1
		if entry.id == operation.stage.stage_id:
			var state := "Perfect clear" if progress.perfect_clear else ("Cleared" if progress.first_clear else "Available")
			var playable := StoryUI.action("%s   %s\n%s" % [entry.id, entry.title, state], true)
			playable.name = "OpenFirstContact"
			playable.alignment = HORIZONTAL_ALIGNMENT_LEFT
			playable.custom_minimum_size.y = 76
			playable.pressed.connect(func() -> void: operation_requested.emit())
			list.add_child(playable)
			playable.grab_focus()
		else:
			var prerequisite: Dictionary = index.nodes[i - 1]
			var reason := "Clear %s to unlock." % prerequisite.title
			if prerequisite.id == operation.stage.stage_id and progress.first_clear:
				reason = "Mechanical and the next operation are unavailable in this build."
			var locked := StoryUI.action("%s   %s · Locked" % [entry.id, entry.title])
			locked.name = "Locked_" + String(entry.id).replace("-", "_")
			locked.alignment = HORIZONTAL_ALIGNMENT_LEFT
			locked.disabled = true
			list.add_child(locked)
			list.add_child(StoryUI.label(reason, 18, StoryUI.INK))
	if visible_count < index.nodes.size():
		list_panel.add_child(StoryUI.label("Control upgrades reveal the remaining routes.", 18, StoryUI.INK))

	var feature := StoryUI.panel(body)
	feature.add_child(StoryUI.label(operation.title, 34))
	feature.add_child(StoryUI.label("T01 · %d waves · %d enemies" % [operation.stage.waves.size(), operation.stage.enemy_count()], 19, StoryUI.BEIGE))
	var map := BattleBoard.new()
	map.battle_map = operation.stage.map
	map.routes = operation.stage.routes
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feature.add_child(map)
	feature.add_child(StoryUI.label("Stop threats before they reach the forest tunnel.", 20))
