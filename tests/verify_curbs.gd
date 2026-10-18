extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func solid(parent: Node, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	solid(world, Vector3(0, -0.5, 0), Vector3(100, 1, 100))
	solid(world, Vector3(0, 0.07, -12), Vector3(20, 0.14, 12))
	solid(world, Vector3(0, 1.5, -30), Vector3(20, 3, 1))
	var car: CharacterBody3D = load("res://vehicles/arcade_car.tscn").instantiate()
	car.position = Vector3(0, 0.1, 3)
	world.add_child(car)
	car.set_physics_process(false)
	var top := 0.0
	for frame in range(400):
		car.call("_step_motion", 1.0 / 60, 1.0, 0.0, false, false)
		top = maxf(top, car.position.y)
		await physics_frame
	assert(car.position.z < -20 and top >= 0.13, "Car traverses ordinary 14cm curb")
	assert(car.position.z > -28, "Tall walls remain solid")
	print("PASS: curb climb, sidewalk crossing/descent, tall-wall rejection")
	quit()
