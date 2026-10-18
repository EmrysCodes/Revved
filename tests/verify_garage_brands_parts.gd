extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var settings: Node = root.get_node("GameSettings")
	settings.settings_path = "res://tests/brands-parts.tmp"
	settings.set_performance(0, 0, 0, false)
	settings.set_performance_brands(0, 0, 0, false)
	settings.set_kit_preset(0, false)
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
	var rows: VBoxContainer = garage.get_node("Frame/Stack/Content/Options/Padding/Rows")
	var preview: Node3D = garage.get_node("Frame/Stack/Content/Preview/Viewport/Stage/Car")
	var stock := Vector4(car.top_speed, car.acceleration, car.braking, car.road_grip)
	for tier in range(1, 4):
		settings.set_performance(tier, tier, tier, false)
		settings.set_performance_brands(0, 0, 0, false)
		var balanced: Dictionary = settings.performance_multipliers()
		settings.set_performance_brands(1, 1, 1, false)
		var launch: Dictionary = settings.performance_multipliers()
		assert(launch.top_speed < balanced.top_speed and launch.acceleration > balanced.acceleration, "Same-tier launch tradeoff")
		assert(launch.braking > balanced.braking, "Bite brake variant")
		settings.set_performance_brands(2, 2, 2, false)
		var speed: Dictionary = settings.performance_multipliers()
		assert(speed.top_speed > balanced.top_speed and speed.acceleration < balanced.acceleration, "Same-tier speed tradeoff")
		assert(speed.braking < balanced.braking, "Control brake variant")
		assert(is_equal_approx(car.top_speed, stock.x * speed.top_speed) and is_equal_approx(car.road_grip, stock.w * speed.grip), "Brands must affect real controller")
		assert(settings.engine_level == tier and settings.brakes_level == tier and settings.tires_level == tier, "Brands retain tier")
	settings.set_performance(0, 0, 0, false)
	assert(Vector4(car.top_speed, car.acceleration, car.braking, car.road_grip).is_equal_approx(stock), "All brands are neutral at stock")
	garage.open_garage()
	assert(rows.get_node("EngineBrand").disabled)
	rows.get_node("Engine").select(2)
	rows.get_node("Engine").item_selected.emit(2)
	assert(not rows.get_node("EngineBrand").disabled)
	rows.get_node("EngineBrand").select(1)
	rows.get_node("EngineBrand").item_selected.emit(1)
	assert(settings.engine_brand == 1 and garage.get_node("Frame/Stack/Content/Preview/StatsPanel/Padding/Stats").text.contains("+58%"), "UI and summary reflect brand")
	garage.get_node("Frame/Stack/Sections").current_tab = 1
	var count := 0
	for kit in range(3):
		settings.set_kit_preset(kit, false)
		for front in range(3):
			for rear in range(3):
				for skirts in range(3):
					settings.set_body_parts(front, rear, skirts, false)
					for model in [visual, preview]:
						assert(model.get_node("Body").get_child_count() == 4, "No duplicated body sections")
						for slot in range(4):
							var index: int = [kit, front, rear, skirts][slot]
							var part: MeshInstance3D = model.get_node("Body/" + model.PART_NAMES[slot])
							assert(part.mesh.resource_path.ends_with("_%d.res" % index), "Selected part must reach preview and car")
					count += 1
					await process_frame
	settings.set_kit_preset(0, false)
	garage.open_garage()
	garage.get_node("Frame/Stack/Sections").current_tab = 1
	rows.get_node("FrontBumper").select(2)
	rows.get_node("FrontBumper").item_selected.emit(2)
	assert(settings.front_bumper == 2 and settings.rear_bumper == 0 and settings.side_skirts == 0, "Part UI changes one slot")
	rows.get_node("Paint").select(4)
	rows.get_node("Paint").item_selected.emit(4)
	assert(settings.front_bumper == 2, "Paint must preserve mixed parts")
	rows.get_node("Body").item_selected.emit(0)
	assert(settings.front_bumper == 0, "Reapplying same kit resets custom parts")
	settings.set_performance(2, 1, 3, false)
	settings.set_performance_brands(1, 2, 1, false)
	settings.set_body_parts(2, 1, 0)
	var restored: Node = load("res://core/game_settings.gd").new()
	restored.settings_path = settings.settings_path
	root.add_child(restored)
	assert(restored.front_bumper == 2 and restored.rear_bumper == 1 and restored.side_skirts == 0)
	assert(restored.engine_brand == 1 and restored.brakes_brand == 2 and restored.tires_brand == 1 and restored.engine_level == 2, "Brands and slots survive reload")
	restored.queue_free()
	var legacy := ConfigFile.new()
	legacy.set_value("car", "body", 2)
	assert(legacy.save(settings.settings_path) == OK)
	var migrated: Node = load("res://core/game_settings.gd").new()
	migrated.settings_path = settings.settings_path
	root.add_child(migrated)
	assert(migrated.front_bumper == 2 and migrated.rear_bumper == 2 and migrated.side_skirts == 2 and migrated.engine_brand == 0, "Old kit saves retain complete appearance")
	migrated.queue_free()
	assert(settings.set_body_parts(-1, 0, 0, false) == ERR_INVALID_PARAMETER)
	assert(settings.set_performance_brands(3, 0, 0, false) == ERR_INVALID_PARAMETER)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.settings_path))
	print("PASS: same-tier brand tradeoffs, live stats, stock neutrality, UI, ", count, " mixed bodies in preview/car, preset reapply, independent paint, persistence, legacy migration, validation")
	quit()
