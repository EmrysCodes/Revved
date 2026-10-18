extends SceneTree
## Render at 120 FPS while physics runs at 30 Hz to expose unsmoothed camera targets.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings: Node = root.get_node("GameSettings")
	var old_perf := Vector3i(settings.engine_level, settings.brakes_level, settings.tires_level)
	settings.set_performance(0, 0, 0, false)
	Engine.physics_ticks_per_second = 30
	var floor_body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1000, 0.5, 1000)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.25
	root.add_child(floor_body)
	var car: CharacterBody3D = load("res://vehicles/arcade_car.tscn").instantiate()
	car.position.y = 1.0
	root.add_child(car)
	for frame in range(40):
		await physics_frame
	assert(car.is_on_floor())
	car.set_process(false)
	car.rolling_drag = 0.0
	car.velocity = Vector3.FORWARD * 15.0
	var arm: SpringArm3D = car.get_node("CameraArm")
	assert(ProjectSettings.get_setting("physics/common/physics_interpolation"))
	assert(arm.top_level and arm.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF)
	for frame in range(15):
		await process_frame
	var raw_steps: Array[float] = []
	var rendered_steps: Array[float] = []
	var previous_raw: float = car.global_position.z
	var previous_rendered: float = car.get_global_transform_interpolated().origin.z
	var minimum_y: float = car.global_position.y
	var maximum_y: float = minimum_y
	for frame in range(120):
		await process_frame
		var target: Transform3D = car.get_global_transform_interpolated()
		raw_steps.append(car.global_position.z - previous_raw)
		rendered_steps.append(target.origin.z - previous_rendered)
		previous_raw = car.global_position.z
		previous_rendered = target.origin.z
		minimum_y = minf(minimum_y, car.global_position.y)
		maximum_y = maxf(maximum_y, car.global_position.y)
		var old_camera: Vector3 = arm.global_position
		car.call("_process", 1.0 / 120.0)
		var expected: Vector3 = old_camera.lerp(target.origin + Vector3.UP * 1.5, 1.0 - exp(-14.0 / 120.0))
		assert(arm.global_position.is_equal_approx(expected), "Camera must follow rendered, interpolated target")
	var raw_variance: float = _variance(raw_steps)
	var render_variance: float = _variance(rendered_steps)
	print("Movement-step variance: raw=", raw_variance, " rendered=", render_variance, "; road-height variation=", maximum_y - minimum_y)
	assert(raw_variance > 0.01 and render_variance < raw_variance * 0.2, "Interpolated target must smooth tick-rate stepping")
	assert(maximum_y - minimum_y < 0.002, "Car must not physically bounce on flat road")
	car.call("_reset_car")
	assert(car.velocity.is_zero_approx() and car.get("_drift_blend") == 0.0)
	assert(arm.global_position.is_equal_approx(car.global_position + Vector3.UP * 1.5), "Reset must snap camera")
	settings.set_performance(old_perf.x, old_perf.y, old_perf.z, false)
	print("PASS: render/physics smoothing, interpolated chase target, stable road contact, reset")
	quit()

func _variance(values: Array[float]) -> float:
	var mean: float = 0.0
	for value in values:
		mean += value / values.size()
	var result: float = 0.0
	for value in values:
		result += (value - mean) * (value - mean) / values.size()
	return result
