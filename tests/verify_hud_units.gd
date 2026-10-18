extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings: Node = root.get_node("GameSettings")
	var original: int = settings.unit_system
	settings.set_unit_system(0, false)
	assert(settings.format_speed(26.8224) == "060 MPH", "60 MPH conversion")
	assert(settings.format_speed(-26.8224) == "060 MPH", "Reverse speed uses magnitude")
	assert(settings.format_distance(1609.344) == "1.00 mi", "Mile conversion")
	assert(settings.format_distance(0.3048, true) == "1 ft", "Foot conversion")
	settings.set_unit_system(1, false)
	assert(settings.format_speed(10.0) == "036 km/h", "Metric speed")
	assert(settings.format_distance(1000.0) == "1.00 km", "Metric distance")
	assert(settings.format_distance(12.0, true) == "12 m", "Metric short distance")
	assert(settings.set_unit_system(99, false) == ERR_INVALID_PARAMETER, "Reject invalid unit preference")
	# Exercise persistence in an isolated file, without changing player preferences.
	var probe: Node = load("res://core/game_settings.gd").new()
	probe.settings_path = "res://tests/units-verification.tmp"
	root.add_child(probe)
	assert(probe.set_unit_system(1) == OK, "Unit preference must save")
	var restored: Node = load("res://core/game_settings.gd").new()
	restored.settings_path = probe.settings_path
	root.add_child(restored)
	assert(restored.unit_system == 1, "Saved unit preference must load")
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(probe.settings_path)) == OK)
	probe.queue_free()
	restored.queue_free()
	settings.set_unit_system(0, false)
	var level: Node3D = load("res://scenes/test_circuit.tscn").instantiate()
	root.add_child(level)
	var car: CharacterBody3D = level.get_node("VehicleSpawn/PlayerCar")
	for frame in range(10):
		await process_frame
	var drive: Control = car.get_node("HUD/Screen/DrivePanel")
	var race: Control = level.get_node("RaceHUD/Screen/RacePanel")
	for resolution in [Vector2i(640, 360), Vector2i(800, 600), Vector2i(1280, 720), Vector2i(1656, 932), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		root.size = resolution
		for frame in range(5):
			await process_frame
		var viewport_rect: Rect2 = root.get_visible_rect()
		for panel in [drive, race]:
			var rect: Rect2 = panel.get_global_rect()
			assert(viewport_rect.encloses(rect), "HUD panel must fit viewport at %s" % resolution)
		assert(not drive.get_global_rect().intersects(race.get_global_rect()), "HUD panels must not overlap")
		for label in [car.get_node("HUD/Screen/DrivePanel/Padding/Stack/Readout"), car.get_node("HUD/Screen/DrivePanel/Padding/Stack/Controls"), level.get_node("RaceHUD/Screen/RacePanel/Padding/Readout")]:
			assert(label.size.y >= label.get_minimum_size().y, "Label content must fit")
		print("PASS HUD bounds and separation: ", resolution, " logical viewport ", viewport_rect.size)
	assert(car.get_node("HUD/Screen/DrivePanel/Padding/Stack/Readout").text.ends_with("MPH"))
	assert(level.readout.text.contains("mi"))
	settings.set_unit_system(1, false)
	for frame in range(5):
		await physics_frame
	assert(car.get_node("HUD/Screen/DrivePanel/Padding/Stack/Readout").text.ends_with("km/h"), "Speed reacts to unit changes")
	assert(level.readout.text.contains("km"), "Distance reacts to unit changes")
	settings.set_unit_system(original, false)
	print("PASS: US/metric conversions, invalid preferences, save/load, live unit changes")
	quit()
