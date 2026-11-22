class_name HeadquartersOverview
extends VBoxContainer

signal back_requested
signal room_requested(room: HeadquartersRoom)

var progress: CampaignProgress

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	StoryUI.header(self, "Headquarters", func() -> void: back_requested.emit(), "%s Funds" % StoryUI.funds(progress.funds()))
	var floor_plan := StoryUI.scroll_column(self)
	var roof := ColorRect.new()
	roof.custom_minimum_size.y = 12
	roof.color = Color("#a69473")
	floor_plan.add_child(roof)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	floor_plan.add_child(grid)
	for room: HeadquartersRoom in CampaignProgress.HEADQUARTERS.rooms:
		_add_room(grid, room)
	var blank := HeadquartersOfficeArt.new()
	blank.custom_minimum_size.y = 98
	grid.add_child(blank)
	var lobby := ColorRect.new()
	lobby.custom_minimum_size.y = 20
	lobby.color = Color("#a69473")
	floor_plan.add_child(lobby)
	add_child(StoryUI.label("Placeholder HQ art", 16, StoryUI.BEIGE))

func _add_room(grid: GridContainer, room: HeadquartersRoom) -> void:
	var level := progress.room_level(room.id)
	var button := StoryUI.action("")
	button.name = "Room_" + String(room.id).get_slice(".", 1)
	button.tooltip_text = room.label
	button.custom_minimum_size = Vector2(240, 106)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: room_requested.emit(room))
	grid.add_child(button)
	var interior := VBoxContainer.new()
	interior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interior.add_theme_constant_override("separation", 6)
	button.add_child(interior)
	interior.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interior.offset_left = 13
	interior.offset_right = -13
	interior.offset_top = 8
	interior.offset_bottom = -8
	var strip := StoryUI.row(interior, 6)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := StoryUI.label(room.label, 20, StoryUI.INK)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(title)
	var state := "Lv.%d" % level if level > 0 else "Unbuilt"
	var status := StoryUI.label(state, 18, StoryUI.INK)
	status.name = "RoomLevel"
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(status)
	var art := HeadquartersOfficeArt.new()
	art.name = "OfficeInterior"
	art.built = level > 0
	art.role = room.role
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	interior.add_child(art)
