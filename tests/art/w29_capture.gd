extends SceneTree
## Native proof crops from the actual review fixtures and shipped textures.

const MENU := preload("res://tests/art/w29_menus/menu_preview.tscn")
const HQ := preload("res://tests/art/w29_hq/hq_preview.tscn")
const PAGES: Array[String] = ["home", "story", "plan", "pause", "settings", "room", "chaos_routes", "garden", "outreach", "records"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1 or DisplayServer.get_name() == "headless":
		push_error("Use a native render and pass a capture directory.")
		quit(1)
		return
	var destination := arguments[0]
	DirAccess.make_dir_recursive_absolute(destination)
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for frame: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
		viewport.size = frame
		var size_key := "%dx%d" % [frame.x, frame.y]
		var menu := MENU.instantiate() as Control
		viewport.add_child(menu)
		for page: String in PAGES:
			menu.zoom = 1.3 if frame.x == 960 else 1.0
			menu.show_page(page)
			await _capture(viewport, destination.path_join("menu_%s_%s.png" % [page, size_key]))
		menu.free()
		var hq := HQ.instantiate() as Control
		viewport.add_child(hq)
		await _capture(viewport, destination.path_join("hq_built_%s.png" % size_key))
		hq._toggle_rooms()
		await _capture(viewport, destination.path_join("hq_opening_%s.png" % size_key))
		hq.free()
	viewport.free()
	print("W29 captured %d actual framebuffers on %s." % [2 * (PAGES.size() + 2), DisplayServer.get_name()])
	quit()

func _capture(view: SubViewport, path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	assert(image.get_size() == view.size and image.save_png(path) == OK, path)
