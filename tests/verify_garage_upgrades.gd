extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings: Node = root.get_node("GameSettings")
	var old_path: String = settings.settings_path
	var old_perf := Vector3i(settings.engine_level, settings.brakes_level, settings.tires_level)
	var old_vinyl := Vector2i(settings.car_vinyl, settings.car_vinyl_color)
	settings.settings_path = "res://tests/upgrades-verification.tmp"
	settings.set_performance_brands(0, 0, 0, false)
	settings.set_performance(0, 0, 0, false)
	settings.set_vinyl(0, 0, false)
	var level: Node3D = load("res://scenes/test_circuit.tscn").instantiate()
	root.add_child(level)
	root.size = Vector2i(1280, 720)
	for frame in range(15):
		await process_frame
	var car: CharacterBody3D = level.get_node("VehicleSpawn/PlayerCar")
	var menu: CanvasLayer = car.get_node("PauseMenu")
	var garage: Control = menu.get_node("Garage")
	var rows: VBoxContainer = garage.get_node("Frame/Stack/Content/Options/Padding/Rows")
	var tabs: TabBar = garage.get_node("Frame/Stack/Sections")
	var visual: Node3D = car.get_node("Visuals/S64Compact")
	var preview: Control = garage.get_node("Frame/Stack/Content/Preview")
	menu.open_menu()
	menu.call("_open_garage")
	assert(tabs.tab_count == 3 and rows.get_node("Engine").visible and not rows.get_node("Body").visible, "Garage categories")
	var body: Node3D = visual.get_node("Body")
	var stock_speed: float = car.top_speed
	var stock_acceleration: float = car.acceleration
	var stock_braking: float = car.braking
	var stock_grip: float = car.road_grip
	rows.get_node("Engine").select(3)
	rows.get_node("Brakes").select(2)
	rows.get_node("Tires").select(1)
	rows.get_node("Engine").item_selected.emit(3)
	assert(is_equal_approx(car.top_speed, stock_speed * 1.30) and is_equal_approx(car.acceleration, stock_acceleration * 1.82), "Engine upgrades must change driving stats")
	assert(is_equal_approx(car.braking, stock_braking * 1.20) and is_equal_approx(car.road_grip, stock_grip * 1.08), "Brake/tire upgrades must change driving stats")
	assert(visual.get_node("Body") == body, "Performance upgrades must not change visual meshes")
	settings.set_performance(3, 2, 1, false)
	assert(is_equal_approx(car.acceleration, stock_acceleration * 1.82), "Reapplying upgrades must not stack multipliers")
	var upgraded_stats := Vector3(car.top_speed, car.acceleration, car.braking)
	tabs.current_tab = 1
	assert(rows.get_node("Body").visible and not rows.get_node("Engine").visible and not rows.get_node("Paint").visible)
	rows.get_node("Body").select(2)
	rows.get_node("Body").item_selected.emit(2)
	assert(Vector3(car.top_speed, car.acceleration, car.braking).is_equal_approx(upgraded_stats), "Cosmetics must not affect performance")
	tabs.current_tab = 2
	assert(rows.get_node("Paint").visible and rows.get_node("Vinyl").visible and not rows.get_node("Wheels").visible)
	for style in [1, 2]:
		rows.get_node("Vinyl").select(style)
		rows.get_node("VinylColor").select(2)
		rows.get_node("Vinyl").item_selected.emit(style)
		var found: bool = false
		for mesh in visual.get_node("Body").find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				if mesh.mesh.surface_get_material(surface).resource_name == "Car":
					var material: Material = mesh.get_surface_override_material(surface)
					assert(material is ShaderMaterial and material.get_shader_parameter("vinyl_style") == style)
					assert(material.get_shader_parameter("vinyl_color").is_equal_approx(visual.VINYL_COLORS[2]))
					assert(material.get_shader_parameter("mesh_to_car") is Transform3D)
					found = true
		assert(found, "Vinyl must be assigned to paintable body surfaces")
	assert(visual.VINYL_SHADER.get_shader_uniform_list().size() >= 6, "Vinyl shader must parse and expose its material parameters")
	rows.get_node("Vinyl").select(0)
	rows.get_node("Vinyl").item_selected.emit(0)
	for mesh in visual.get_node("Body").find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material: Material = mesh.get_surface_override_material(surface)
			assert(not material is ShaderMaterial, "Removing vinyl must remove shader overrides")
	var before_yaw: float = garage.get_node("Frame/Stack/Content/Preview/Viewport/Stage/Car").rotation.y
	for frame in range(3):
		await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.position = preview.get_global_rect().get_center()
	click.global_position = click.position
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	for frame in range(3):
		await process_frame
	assert(garage.get("_dragging"), "Clicking actual preview must begin dragging")
	var motion := InputEventMouseMotion.new()
	motion.position = click.position + Vector2(100, 40)
	motion.relative = Vector2(100, 40)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	assert(garage.get_node("Frame/Stack/Content/Preview/Viewport/Stage/Car").rotation.y > before_yaw + 0.7, "Mouse dragging must rotate car")
	assert(garage.get("_orbit_pitch") > 0.4, "Vertical dragging must tilt inspection camera")
	var release: InputEventMouseButton = click.duplicate()
	release.pressed = false
	release.position = Vector2(1, 1)
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	assert(not garage.get("_dragging"), "Releasing outside preview must stop dragging")
	for resolution in [Vector2i(640, 360), Vector2i(800, 600), Vector2i(1280, 720), Vector2i(2560, 1080)]:
		root.size = resolution
		for section in range(3):
			tabs.current_tab = section
			for frame in range(5):
				await process_frame
			assert(garage.get_node("Frame/Stack/Content").get_global_rect().encloses(garage.get_node("Frame/Stack/Content/Options").get_global_rect()), "All categories must fit at supported sizes")
	settings.set_vinyl(2, 1)
	var restored: Node = load("res://core/game_settings.gd").new()
	restored.settings_path = settings.settings_path
	root.add_child(restored)
	assert(restored.engine_level == 3 and restored.brakes_level == 2 and restored.tires_level == 1 and restored.car_vinyl == 2 and restored.car_vinyl_color == 1, "Upgrades and vinyl must persist")
	restored.queue_free()
	assert(settings.set_performance(4, 0, 0, false) == ERR_INVALID_PARAMETER)
	assert(settings.set_vinyl(-1, 0, false) == ERR_INVALID_PARAMETER)
	menu.close_menu()
	settings.set_performance(0, 0, 0, false)
	assert(is_equal_approx(car.top_speed, stock_speed) and is_equal_approx(car.acceleration, stock_acceleration), "Stock selection must restore stock stats")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.settings_path))
	settings.settings_path = old_path
	settings.set_performance(old_perf.x, old_perf.y, old_perf.z, false)
	settings.set_vinyl(old_vinyl.x, old_vinyl.y, false)
	print("PASS: categories, independent performance/cosmetics, non-stacking upgrades, vinyl assignment/removal, actual mouse drag/tilt/release, responsive layouts, persistence, stock restore")
	quit()
