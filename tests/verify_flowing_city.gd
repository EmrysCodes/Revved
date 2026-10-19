extends "res://tests/verify_hartford_driving.gd"
func _run() -> void:
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate()
	root.add_child(city)
	var car: CharacterBody3D=city.get_node("VehicleSpawn/PlayerCar")
	car.set_physics_process(false)
	for frame in range(10):
		await physics_frame
	drive_speed=30.0
	var routes: Array=city.get_meta("flowing_routes")
	for index in range(routes.size()):
		var path: PackedVector3Array=routes[index]
		assert(path[0].distance_to(path[-1])<0.01,"Boulevard is a closed loop")
		var sharpest:=0.0
		for i in range(1,path.size()-1):
			var before:=Vector2(path[i].x-path[i-1].x,path[i].z-path[i-1].z)
			var after:=Vector2(path[i+1].x-path[i].x,path[i+1].z-path[i].z)
			assert(before.length()>0.01 and after.length()>0.01,"No duplicate road samples")
			sharpest=maxf(sharpest,absf(before.angle_to(after)))
		assert(sharpest<0.12,"Smooth bends replace square boulevard corners")
		await drive(car,path,"CurvedBoulevard_%d_at_67MPH"%index)
	drive_speed=18.0
	var infill: Array=city.get_meta("infill_routes")
	for index in range(infill.size()-4,infill.size()):
		await drive(car,infill[index],"NeighborhoodArterialLink_%d"%index)
	print("PASS: four smooth closed boulevards at 67 MPH and four connected local approaches")
	quit()
