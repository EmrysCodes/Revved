extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings: Node = root.get_node("GameSettings")
	var original_path: String = settings.settings_path
	var original_units: int = settings.unit_system
	settings.settings_path = "res://tests/pause-menu-verification.tmp"
	settings.set_unit_system(0, false)
	var level: Node3D = load("res://scenes/test_circuit.tscn").instantiate()
	root.add_child(level)
	var car: CharacterBody3D = level.get_node("VehicleSpawn/PlayerCar")
	var menu: CanvasLayer = car.get_node("PauseMenu")
	var card: Control = menu.get_node("Overlay/Center/Card")
	var stack: VBoxContainer = menu.get_node("Overlay/Center/Card/Padding/Stack")
	var units: OptionButton = stack.get_node("UnitsRow/Units")
	for frame in range(60):
		await physics_frame
	assert(not paused and not menu.get_node("Overlay").visible)
	level.lap_active = true
	level.next_gate = 1
	level.elapsed = 12.5
	level.best_lap = 60.0
	car.velocity = Vector3.FORWARD * 10.0
	_key(KEY_ESCAPE)
	assert(paused and menu.get_node("Overlay").visible, "Escape must open pause menu")
	assert(root.gui_get_focus_owner() == stack.get_node("Resume"), "Resume must receive initial keyboard focus")
	_key(KEY_TAB)
	assert(root.gui_get_focus_owner() == stack.get_node("Restart"), "Tab must navigate menu controls")
	units.grab_focus()
	units.show_popup()
	for frame in range(3):
		await process_frame
	assert(units.get_popup().visible, "Units dropdown must open")
	_key(KEY_ESCAPE)
	for frame in range(3):
		await process_frame
	assert(paused and not units.get_popup().visible, "Escape should dismiss dropdown before resuming driving")
	var position_before: Vector3 = car.global_position
	var time_before: float = level.elapsed
	_key(KEY_W)
	_key(KEY_R)
	for frame in range(30):
		await process_frame
	assert(car.global_position.is_equal_approx(position_before), "Driving and reset inputs must not move car while paused")
	assert(level.elapsed == time_before, "Lap timer must freeze")
	for resolution in [Vector2i(640, 360), Vector2i(800, 600), Vector2i(1280, 720), Vector2i(1656, 932), Vector2i(2560, 1080)]:
		root.size = resolution
		for frame in range(5):
			await process_frame
		assert(root.get_visible_rect().encloses(card.get_global_rect()), "Pause card must fit viewport")
		assert(card.get_global_rect().encloses(stack.get_global_rect()), "Menu controls must fit card")
	units.select(1)
	units.item_selected.emit(1)
	assert(settings.unit_system == 1, "Menu must change unit preference")
	assert(level.readout.text.contains("km"), "Race HUD must update while paused")
	assert(car.get_node("HUD/Screen/DrivePanel/Padding/Stack/Readout").text.ends_with("km/h"), "Speed must update while paused")
	var config := ConfigFile.new()
	assert(config.load(settings.settings_path) == OK and config.get_value("display", "units") == 1, "Menu selection must persist")
	assert(stack.get_node("Feedback").text == "Unit preference saved.")
	_key(KEY_ESCAPE)
	assert(not paused and not menu.get_node("Overlay").visible, "Escape must resume")
	for frame in range(5):
		await physics_frame
	assert(level.elapsed > time_before and car.global_position.z < position_before.z, "Driving and timer must resume")
	_key(KEY_ESCAPE)
	assert(units.get_selected_id() == 1, "Reopened menu must reflect preference")
	stack.get_node("Restart").pressed.emit()
	assert(not paused and not level.lap_active and level.next_gate == 0, "Restart button must reset lap and resume")
	assert(car.global_position.is_equal_approx(Vector3(39, 1, 35)) and car.velocity.is_zero_approx(), "Restart button must restore spawn")
	assert(level.best_lap == 60.0, "Restart must preserve session best")
	menu.open_menu()
	stack.get_node("Resume").pressed.emit()
	assert(not paused, "Resume button must unpause")
	settings.settings_path = "res://tests/nonexistent-save-directory/settings.cfg"
	menu.open_menu()
	units.select(0)
	units.item_selected.emit(0)
	assert(stack.get_node("Feedback").text.contains("Could not save"), "Save failures must be visible")
	assert(settings.unit_system == 0, "Save failure must still apply session preference")
	menu.close_menu()
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/pause-menu-verification.tmp")) == OK)
	settings.settings_path = original_path
	settings.set_unit_system(original_units, false)
	print("PASS: Escape toggle, keyboard focus, paused driving/timer, responsive bounds, live units, persistence, resume/restart, preserved best lap, save-error feedback")
	quit()

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var release: InputEventKey = event.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
