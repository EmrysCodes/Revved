extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var settings: Node = root.get_node("GameSettings")
	settings.settings_path = "res://tests/spoiler-verification.tmp"
	settings.set_spoiler(0, 0, false)
	var level: Node3D = load("res://scenes/test_circuit.tscn").instantiate()
	root.add_child(level)
	for frame in range(10):
		await process_frame
	var car: CharacterBody3D = level.get_node("VehicleSpawn/PlayerCar")
	var visual: Node3D = car.get_node("Visuals/S64Compact")
	var menu: CanvasLayer = car.get_node("PauseMenu")
	menu.open_menu()
	menu.call("_open_garage")
	var garage: Control = menu.get_node("Garage")
	var rows: VBoxContainer = garage.get_node(garage.ROWS)
	var preview: Node3D = garage.get_node("Frame/Stack/Content/Preview/Viewport/Stage/Car")
	var stats := Vector4(car.top_speed, car.acceleration, car.braking, car.road_grip)
	assert(rows.get_node("SpoilerFinish").disabled, "No spoiler disables finish")
	garage.get_node("Frame/Stack/Sections").current_tab = 1
	for kit in range(3):
		settings.set_kit_preset(kit, false)
		for style in range(3):
			for finish in range(2):
				settings.set_spoiler(style, finish, false)
				for model in [visual, preview]:
					var mount: Node3D = model.get_node("Spoiler")
					assert(mount.get_child_count() == (0 if style == 0 else 1), "No duplicate spoiler instances")
					for mesh: MeshInstance3D in mount.find_children("*", "MeshInstance3D", true, false):
						var relative: Transform3D = model.global_transform.affine_inverse() * mesh.global_transform
						var bounds := AABB(relative * mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0], Vector3.ZERO)
						for surface in range(mesh.mesh.get_surface_count()):
							for vertex: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
								bounds = bounds.expand(relative * vertex)
						assert(bounds.position.y > 0.93 and bounds.end.y < 1.31 and bounds.position.z > 1.5 and bounds.end.z < 2.01, "Wing must mount on rear hatch inside car envelope")
						assert(mesh.material_override is StandardMaterial3D)
						assert(mesh.material_override.albedo_color.is_equal_approx(model.PAINT_COLORS[settings.car_paint] if finish == 0 else Color(0.018, 0.021, 0.025)))
				assert(Vector4(car.top_speed, car.acceleration, car.braking, car.road_grip).is_equal_approx(stats), "Spoilers are cosmetic")
				await process_frame
	rows.get_node("Spoiler").select(1)
	rows.get_node("Spoiler").item_selected.emit(1)
	assert(settings.car_spoiler == 1 and not rows.get_node("SpoilerFinish").disabled, "Live spoiler UI")
	rows.get_node("SpoilerFinish").select(0)
	rows.get_node("SpoilerFinish").item_selected.emit(0)
	for paint in range(6):
		settings.set_car_style(settings.car_body, settings.car_wheels, paint, false)
		for model in [visual, preview]:
			var mesh: MeshInstance3D = model.get_node("Spoiler").find_children("*", "MeshInstance3D", true, false)[0]
			assert(mesh.material_override.albedo_color.is_equal_approx(model.PAINT_COLORS[paint]), "Wing follows live paint")
	var a: MeshInstance3D = visual.get_node("Spoiler").find_children("*", "MeshInstance3D", true, false)[0]
	var b: MeshInstance3D = preview.get_node("Spoiler").find_children("*", "MeshInstance3D", true, false)[0]
	assert(a.material_override != b.material_override, "Shared source materials must not be mutated")
	settings.set_body_parts(2, 1, 0, false)
	settings.set_spoiler(2, 1)
	assert(settings.front_bumper == 2 and settings.rear_bumper == 1 and settings.side_skirts == 0, "Spoiler preserves custom parts")
	settings.set_kit_preset(1, false)
	assert(settings.car_spoiler == 2 and settings.spoiler_finish == 1, "Kit presets preserve spoiler")
	garage.open_garage()
	assert(rows.get_node("Spoiler").selected == 2 and rows.get_node("SpoilerFinish").selected == 1, "Reopened UI reflects saved choice")
	var restored: Node = load("res://core/game_settings.gd").new()
	restored.settings_path = settings.settings_path
	root.add_child(restored)
	assert(restored.car_spoiler == 2 and restored.spoiler_finish == 1, "Spoiler persistence")
	restored.queue_free()
	var invalid := ConfigFile.new()
	invalid.set_value("car", "spoiler", 99)
	invalid.set_value("car", "spoiler_finish", -1)
	invalid.save(settings.settings_path)
	var fallback: Node = load("res://core/game_settings.gd").new()
	fallback.settings_path = settings.settings_path
	root.add_child(fallback)
	assert(fallback.car_spoiler == 0 and fallback.spoiler_finish == 0, "Invalid saved values use safe defaults")
	fallback.queue_free()
	assert(settings.set_spoiler(3, 0, false) == ERR_INVALID_PARAMETER)
	assert(settings.set_spoiler(0, -1, false) == ERR_INVALID_PARAMETER)
	settings.set_spoiler(0, 1, false)
	assert(visual.get_node("Spoiler").get_child_count() == 0 and preview.get_node("Spoiler").get_child_count() == 0, "Removing spoiler clears both cars")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.settings_path))
	print("PASS: both spoilers and finishes on all kits, mounting bounds, live paint, isolated materials, UI, persistence, validation, preserved parts/stats, removal")
	quit()
