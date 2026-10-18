extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node3D = load("res://scenes/test_circuit.tscn").instantiate()
	root.add_child(level)
	var car: CharacterBody3D = level.get_node("VehicleSpawn/PlayerCar")
	var visual: Node3D = car.get_node("Visuals/S64Compact")
	var meshes: Array[Node] = visual.find_children("*", "MeshInstance3D", true, false)
	assert(meshes.size() == 8, "Four body sections and four wheels required")
	var bounds := AABB()
	var triangles: int = 0
	for index in range(meshes.size()):
		var mesh: MeshInstance3D = meshes[index]
		var relative: Transform3D = car.global_transform.affine_inverse() * mesh.global_transform
		var mesh_bounds: AABB = relative * mesh.get_aabb()
		bounds = mesh_bounds if index == 0 else bounds.merge(mesh_bounds)
		for surface in range(mesh.mesh.get_surface_count()):
			triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size() / 3
	print("S64 triangles: ", triangles, "; bounds: ", bounds)
	assert(triangles < 10000, "Lightweight car geometry")
	assert(absf(bounds.size.z - 4.0) < 0.02)
	assert(absf(bounds.position.y) < 0.01, "Tire contact must align with car origin")
	assert(bounds.size.x < 1.85 and bounds.size.y < 1.36, "Neutral pose must fit collider")
	visual.update_wheels(1.0, 5.0, 0.1)
	var front: Node3D = visual.get_node("FrontLeft")
	assert(front.rotation.y < -0.5 and front.rotation.y > -0.53, "Front-left wheel must turn right")
	assert(is_equal_approx(front.rotation.y, visual.get_node("FrontRight").rotation.y), "Both front wheels must steer together")
	assert(visual.get_node("RearLeft").rotation.is_zero_approx() and visual.get_node("RearRight").rotation.is_zero_approx(), "Rear steering pivots must remain straight")
	assert(visual.get_node("FrontLeft/Spin").rotation.x < 0.0 and visual.get_node("RearLeft/Spin").rotation.x < 0.0, "All wheels must roll forward")
	visual.reset_wheels()
	visual.update_wheels(-1.0, -5.0, 0.1)
	assert(front.rotation.y > 0.5 and visual.get_node("RearRight/Spin").rotation.x > 0.0, "Left steering and reverse rolling")
	car.call("_reset_car")
	assert(front.rotation.is_zero_approx() and visual.get_node("FrontLeft/Spin").rotation.is_zero_approx(), "Reset clears wheel animation")
	for frame in range(60):
		await physics_frame
	assert(car.is_on_floor() and absf(car.global_position.y - 0.2) < 0.05, "Wheels must rest on road")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	for frame in range(60):
		await physics_frame
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	assert(absf(visual.get_node("RearLeft/Spin").rotation.x) > 0.1, "Controller must animate rolling wheels")
	assert(car.velocity.z < -8.0, "New visual must retain driving behavior")
	print("PASS: modular meshes, triangle budget, road contact, collider fit, front-only steering, forward/reverse wheel rolling, reset, controller integration")
	quit()
