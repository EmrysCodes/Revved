extends SceneTree
## Run headlessly with --script res://tests/verify_handling.gd --fixed-fps 60.

const STEP: float = 1.0 / 60.0
var car: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ground := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1000, 0.5, 1000)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	ground.add_child(collision)
	ground.position.y = -0.25
	root.add_child(ground)
	car = load("res://vehicles/arcade_car.tscn").instantiate()
	car.position.y = 1.0
	root.add_child(car)
	car.set_physics_process(false)
	await _reset()
	for frame in range(60):
		car.call("_step_motion", STEP, 1.0, 0.0, false, false)
		await physics_frame
	assert(car.velocity.z < -car.acceleration * 0.8, "Throttle must accelerate forward")
	for frame in range(300):
		car.call("_step_motion", STEP, 1.0, 0.0, false, false)
		await physics_frame
	assert(Vector2(car.velocity.x, car.velocity.z).length() <= car.top_speed + 0.01, "Speed cap")
	for frame in range(ceili(car.top_speed / car.braking * 60.0) + 10):
		car.call("_step_motion", STEP, 0.0, 0.0, true, false)
		await physics_frame
	assert(Vector2(car.velocity.x, car.velocity.z).length() < 0.1, "Footbrake must stop without reversing")
	await _reset()
	car.call("_step_motion", STEP, 0.0, 1.0, false, false)
	assert(car.get("_steering") > 0.0 and car.get("_steering") < 0.2, "Steering must ramp in")
	for frame in range(60):
		car.call("_step_motion", STEP, 0.0, 1.0, false, true)
		await physics_frame
	assert(absf(car.rotation.y) < 0.001, "No stationary turning")
	var slow: Dictionary = await _turn(8.0, false)
	var fast: Dictionary = await _turn(28.0, false)
	assert(fast.yaw < slow.yaw, "Steering must be calmer at higher speed")
	var grip: Dictionary = await _turn(22.0, false)
	var slide: Dictionary = await _turn(22.0, true)
	print("Slip radians normal / handbrake: ", grip.slip, " / ", slide.slip)
	assert(slide.slip > grip.slip + 0.1, "Handbrake must preserve more lateral momentum")
	assert(slide.speed < grip.speed, "Handbrake must shed speed")
	assert(car.get("_handbraking"), "Handbrake state must activate")
	for frame in range(90):
		car.call("_step_motion", STEP, 1.0, 0.0, false, false)
		await physics_frame
	assert(_slip() < 0.05, "Releasing handbrake must recover grip")
	await _reset()
	car.velocity = Vector3.BACK * 6.0
	for frame in range(20):
		car.call("_step_motion", STEP, -1.0, 1.0, false, false)
		await physics_frame
	assert(car.rotation.y > 0.1, "Reverse steering direction")
	car.call("_process", 0.1)
	var camera: Camera3D = car.get_node("CameraArm/FollowCamera")
	assert(camera.fov > 75.0 and camera.fov <= 82.0, "Speed response must stay within FOV limits")
	car.call("_reset_car")
	assert(car.velocity.is_zero_approx() and car.get("_steering") == 0.0 and car.get("_yaw_rate") == 0.0, "Reset clears handling state")
	assert(camera.fov == 75.0, "Reset restores camera")
	assert(car.get_node("CameraArm").global_position.is_equal_approx(car.global_position + Vector3.UP * 1.5), "Reset snaps camera to car")
	car.set_physics_process(true)
	_key(KEY_W, true)
	for frame in range(60):
		await physics_frame
	_key(KEY_W, false)
	assert(car.velocity.z < -car.acceleration * 0.7, "W key must accelerate")
	_key(KEY_SHIFT, true)
	for frame in range(60):
		await physics_frame
	_key(KEY_SHIFT, false)
	assert(Vector2(car.velocity.x, car.velocity.z).length() < 0.1, "Shift key must brake")
	car.call("_reset_car")
	var wall := StaticBody3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(20, 4, 0.5)
	var wall_collision := CollisionShape3D.new()
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	wall.position = Vector3(0, 2, -30)
	root.add_child(wall)
	_key(KEY_W, true)
	for frame in range(240):
		await physics_frame
	_key(KEY_W, false)
	assert(car.global_position.z > -27.8 and car.global_position.z < -27.0, "Car must reach wall without passing through")
	assert(Vector2(car.velocity.x, car.velocity.z).length() < 0.1, "Wall impact must remove forward velocity")
	_key(KEY_S, true)
	for frame in range(120):
		await physics_frame
	_key(KEY_S, false)
	assert(car.global_position.z > -20.0 and car.velocity.z > 5.0, "S key must reverse away from wall")
	assert(car.velocity.z <= car.reverse_speed + 0.01, "Reverse speed cap")
	print("PASS: throttle, speed caps, braking, steering ramp, stationary turning, speed-sensitive steering, slide, grip recovery, reverse, camera, reset, keyboard input, wall collision")
	quit()


func _reset() -> void:
	car.call("_reset_car")
	for frame in range(40):
		car.call("_step_motion", STEP, 0.0, 0.0, false, false)
		await physics_frame
	assert(car.is_on_floor(), "Test car must be grounded")


func _turn(speed: float, handbrake: bool) -> Dictionary:
	await _reset()
	car.velocity = Vector3.FORWARD * speed
	for frame in range(30):
		car.call("_step_motion", STEP, 0.0, 1.0, false, handbrake)
		await physics_frame
	return {"yaw": absf(car.get("_yaw_rate")), "slip": _slip(), "speed": Vector2(car.velocity.x, car.velocity.z).length()}


func _slip() -> float:
	var planar := Vector3(car.velocity.x, 0.0, car.velocity.z)
	return absf(atan2(planar.dot(car.global_basis.x), planar.dot(-car.global_basis.z)))


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
