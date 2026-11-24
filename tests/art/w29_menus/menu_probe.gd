extends SceneTree

const PREVIEW := preload("res://tests/art/w29_menus/menu_preview.tscn")
var checks := 0
var failures := 0
var clipped: Array[String] = []

func _initialize() -> void:
	call_deferred("_probe")

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _probe() -> void:
	var view := SubViewport.new()
	root.add_child(view)
	var menu := PREVIEW.instantiate() as Control
	view.add_child(menu)
	var surfaces := 0
	var taps := 0
	for viewport_size: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
		view.size = viewport_size
		for text_scale: float in [1.0, 1.3]:
			menu.zoom = text_scale
			for page: String in menu.PAGE_NAMES:
				menu.show_page(page)
				await process_frame
				await process_frame
				_check(menu.active_page == page, "Menu route " + page)
				var action_count := 0
				for button: Button in menu.find_children("*", "Button", true, false):
					if not button.is_visible_in_tree():
						continue
					_check(button.size.y >= 60.0 and button.size.x >= 60.0, page + " touch target " + button.text)
					var scroll := button.find_parent("*ScrollContainer*")
					if scroll == null:
						var box := button.get_global_rect()
						var clip := Rect2(Vector2.ZERO, Vector2(viewport_size)).grow(1.0)
						if not clip.encloses(box):
							clipped.append("%s %d×%d %.1f %s %s" % [page, viewport_size.x, viewport_size.y, text_scale, button.text, box])
					action_count += 1
				taps += action_count
				_check(action_count > 0, page + " has a visible action")
				surfaces += 1
	menu.show_page("home")
	menu.open_page("headquarters")
	menu.go_back()
	_check(menu.active_page == "home", "Backstack returns to Home")
	if not clipped.is_empty():
		for hitbox: String in clipped:
			print("Clipped fixture control: " + hitbox)
	view.free()
	print("W29 menu preview: %d screen cases, %d button targets, %d checks, %d failures, %d clipped controls" % [surfaces,taps,checks,failures,clipped.size()])
	quit(1 if failures > 0 or not clipped.is_empty() else 0)
