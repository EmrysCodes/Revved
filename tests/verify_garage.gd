extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings: Node = root.get_node("GameSettings")
	var old_path: String = settings.settings_path
	var old_style := Vector3i(settings.car_body, settings.car_wheels, settings.car_paint)
	var old_units: int = settings.unit_system
	settings.settings_path = "res://tests/garage-verification.tmp"
	settings.set_car_style(0, 0, 0, false)
	var level: Node3D = load("res://scenes/test_circuit.tscn").instantiate()
	root.add_child(level)
	for frame in range(10):
		await process_frame
	var car: CharacterBody3D = level.get_node("VehicleSpawn/PlayerCar")
	var visual: Node3D = car.get_node("Visuals/S64Compact")
	var menu: CanvasLayer = car.get_node("PauseMenu")
	var garage: Control = menu.get_node("Garage")
	var preview: Node3D = garage.get_node("Frame/Stack/Content/Preview/Viewport/Stage/Car")
	var viewport: SubViewport = garage.get_node("Frame/Stack/Content/Preview/Viewport")
	var rows: VBoxContainer = garage.get_node("Frame/Stack/Content/Options/Padding/Rows")
	assert(not garage.visible and viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Hidden preview must not render")
	menu.open_menu()
	menu.get_node("Overlay/Center/Card/Padding/Stack/Garage").pressed.emit()
	assert(paused and garage.visible and not menu.get_node("Overlay").visible, "Garage must keep driving paused")
	assert(viewport.own_world_3d and viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "Garage preview must render independently")
	for resolution in [Vector2i(640, 360), Vector2i(800, 600), Vector2i(1280, 720), Vector2i(1656, 932), Vector2i(2560, 1080)]:
		root.size = resolution
		for frame in range(5):
			await process_frame
		assert(root.get_visible_rect().encloses(garage.get_node("Frame").get_global_rect()))
		assert(garage.get_node("Frame/Stack/Content").get_global_rect().encloses(garage.get_node("Frame/Stack/Content/Options").get_global_rect()), "Garage controls must fit")
		assert(garage.get_node("Frame/Stack/Content/Preview").size.x > 300.0, "Preview must retain usable width")
	for body in range(3):
		for wheels in range(4):
			var paint: int = (body + wheels) % 6
			rows.get_node("Body").select(body)
			rows.get_node("Wheels").select(wheels)
			rows.get_node("Paint").select(paint)
			rows.get_node("Body").item_selected.emit(body)
			assert(visual.get("_body_index") == body and visual.get("_wheel_index") == wheels)
			assert(preview.get("_body_index") == body and preview.get("_wheel_index") == wheels)
			assert(_paint(visual).albedo_color.is_equal_approx(preview.PAINT_COLORS[paint]), "Paint must reach actual car")
			assert(_paint(preview).albedo_color.is_equal_approx(preview.PAINT_COLORS[paint]), "Paint must reach preview")
			assert(_paint(visual) != _paint(preview), "Paint overrides must not mutate shared imported materials")
			var meshes: Array[Node] = visual.find_children("*", "MeshInstance3D", true, false)
			assert(meshes.size() == 8, "Style swaps must not leave duplicate models")
			var bounds := AABB()
			for index in range(meshes.size()):
				var relative: Transform3D = visual.global_transform.affine_inverse() * meshes[index].global_transform
				var mesh_bounds: AABB = relative * meshes[index].get_aabb()
				bounds = mesh_bounds if index == 0 else bounds.merge(mesh_bounds)
			assert(bounds.size.x < 1.85 and bounds.size.y < 1.36 and bounds.size.z < 4.06, "All kit/wheel combinations must fit car envelope")
			visual.update_wheels(1.0, 5.0, 0.1)
			assert(visual.get_node("FrontLeft").rotation.y < -0.5 and absf(visual.get_node("RearLeft/Spin").rotation.x) > 0.1, "Wheel pivots must survive style swaps")
			car.call("_reset_car")
			await process_frame
	for paint in range(6):
		settings.set_car_style(0, 0, paint, false)
		assert(_paint(visual).albedo_color.is_equal_approx(visual.PAINT_COLORS[paint]))
	assert(settings.set_car_style(3, 0, 0, false) == ERR_INVALID_PARAMETER)
	assert(settings.set_car_style(0, -1, 0, false) == ERR_INVALID_PARAMETER)
	assert(settings.set_car_style(0, 0, 6, false) == ERR_INVALID_PARAMETER)
	settings.set_car_style(2, 3, 4)
	settings.set_unit_system(1)
	var restored: Node = load("res://core/game_settings.gd").new()
	restored.settings_path = settings.settings_path
	root.add_child(restored)
	assert(restored.car_body == 2 and restored.car_wheels == 3 and restored.car_paint == 4 and restored.unit_system == 1, "Style and unit preferences must save together")
	restored.queue_free()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	Input.flush_buffered_events()
	assert(paused and not garage.visible and menu.get_node("Overlay").visible, "Escape must return to pause menu")
	assert(viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Leaving garage must stop preview rendering")
	menu.call("_open_garage")
	assert(rows.get_node("Body").selected == 2 and rows.get_node("Wheels").selected == 3 and rows.get_node("Paint").selected == 4, "Reopened garage must reflect saved choices")
	settings.settings_path = "res://tests/nonexistent-garage-directory/settings.cfg"
	rows.get_node("Paint").select(1)
	rows.get_node("Paint").item_selected.emit(1)
	assert(rows.get_node("Feedback").text.contains("Could not save"), "Garage must explain persistence failure")
	settings.settings_path = "res://tests/garage-verification.tmp"
	menu.close_menu()
	assert(not paused)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.settings_path)) == OK)
	settings.settings_path = old_path
	settings.set_car_style(old_style.x, old_style.y, old_style.z, false)
	settings.set_unit_system(old_units, false)
	print("PASS: garage navigation, responsive layout, all 12 body/wheel combinations, six paints, wheel animation after swaps, shared live preview, combined persistence, invalid preferences")
	quit()

func _paint(visual: Node3D) -> StandardMaterial3D:
	for mesh in visual.get_node("Body").find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			if mesh.mesh.surface_get_material(surface).resource_name == "Car":
				return mesh.get_surface_override_material(surface)
	return null
