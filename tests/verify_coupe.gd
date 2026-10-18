extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node3D = load("res://scenes/test_circuit.tscn").instantiate()
	root.add_child(level)
	var car: CharacterBody3D = level.get_node("VehicleSpawn/PlayerCar")
	var visuals: Node3D = car.get_node("Visuals")
	var meshes: Array[Node] = visuals.find_children("*", "MeshInstance3D", true, false)
	assert(meshes.size() == 1, "Imported model must replace all placeholder meshes")
	var mesh_instance: MeshInstance3D = meshes[0]
	var relative: Transform3D = car.global_transform.affine_inverse() * mesh_instance.global_transform
	var bounds: AABB = relative * mesh_instance.get_aabb()
	print("Car-local visual bounds: ", bounds)
	assert(absf(bounds.size.z - 4.0) < 0.02, "Model should be approximately 13.12 feet long")
	assert(bounds.size.x > 1.7 and bounds.size.x < 1.85, "Model width must fit existing collider")
	assert(absf(bounds.position.y) < 0.01, "Wheel contact height must align with origin")
	assert(absf(bounds.get_center().x) < 0.01 and absf(bounds.get_center().z) < 0.01, "Visual must be centered")
	var shape: BoxShape3D = car.get_node("Collision").shape
	assert(bounds.size.x <= shape.size.x and bounds.size.y <= shape.size.y and bounds.size.z <= shape.size.z)
	var triangles: int = mesh_instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3
	assert(triangles < 100000, "Game model should use optimized geometry")
	assert(is_equal_approx(car.get_node("Visuals/JDMCoupe/ImportedModel").rotation.y, -PI / 2.0), "Model nose must face -Z")
	for frame in range(60):
		await physics_frame
	assert(car.is_on_floor(), "Imported car must settle onto road")
	assert(absf(car.global_position.y - 0.2) < 0.05, "Wheels must rest at road height")
	print("PASS: imported visual, dimensions, centered origin, orientation, collider coverage, triangle budget, road contact")
	quit()
