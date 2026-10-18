extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func drive(car: CharacterBody3D,path: PackedVector3Array,label: String) -> void:
	car.global_position=path[0]+Vector3.UP*0.25
	car.rotation.y=atan2(-(path[1].x-path[0].x),-(path[1].z-path[0].z))
	car.velocity=Vector3.ZERO
	car.set("_steering",0.0);car.set("_yaw_rate",0.0)
	car.reset_physics_interpolation()
	for frame in range(18):
		car.call("_step_motion",1.0/60,0.0,0.0,false,false)
		await physics_frame
	car.top_speed=18
	var target:=1
	var length:=0.0
	for i in range(path.size()-1):
		length+=path[i].distance_to(path[i+1])
	var finished:=false
	var air:=0
	for frame in range(ceili(length/18*60)+600):
		while target<path.size()-1 and Vector2(car.position.x-path[target].x,car.position.z-path[target].z).length()<12:
			target+=1
		var desired: Vector3=path[target]-car.position
		desired.y=0
		if target==path.size()-1 and desired.length()<7:
			finished=true
			break
		var angle:=(-car.global_basis.z).signed_angle_to(desired.normalized(),Vector3.UP)
		car.call("_step_motion",1.0/60,1.0,clampf(-angle*2.4,-1,1),false,false)
		if not car.is_on_floor():
			air+=1
		await physics_frame
	print("DRIVE ",label," finished ",finished," air ",air," position ",car.position)
	assert(finished,"Drive entire authored connector")
	assert(air<100,"No extended falling or ramp clipping")
func _run() -> void:
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate()
	root.add_child(city)
	var car: CharacterBody3D=city.get_node("VehicleSpawn/PlayerCar")
	car.set_physics_process(false)
	for frame in range(10):
		await physics_frame
	var infill: Array=city.get_meta("infill_routes")
	for index in [0,8,20,40,60,80,100]:
		await drive(car,infill[index],"Neighborhood_%d"%index)
	var routes: Dictionary=city.get_meta("named_routes")
	for key in ["Downtown_to_I84_E","I84_E_to_I91_S","I91_S_to_I84_W","I84_W_to_I91_N","I91_N_to_I84_E","I84_E_to_R2_S","R2_N_to_I84_W","I91_S_to_R3_E","R3_W_to_I91_N","R3_W_to_I91_S","R3_E_to_R2_N","R2_S_to_R3_W","I84_W_to_Downtown"]:
		await drive(car,routes[key],key)
	for index in [16,18,20,22,24,26,28,30]:
		await drive(car,city.ramp_roads[index],"Perimeter_%d"%index)
	# Drive through both glass fronts of the first arcade.
	var location: Vector3=city.get_meta("glass_locations")[0]
	var path:=PackedVector3Array([location+Vector3(0,0.1,-50),location+Vector3(0,0.1,50)])
	await drive(car,path,"GlassArcade")
	var broken:=0
	for pane in city.get_node("Shortcuts").get_children():
		if pane is Area3D and pane.get("broken"):
			broken+=1
	assert(broken>=2,"Both arcade glass fronts shatter when driven through")
	assert(not city.get_node("Shortcuts").find_children("*","Area3D",true,false).is_empty())
	print("PASS: real-car highway connector and perimeter ramp drives, glass-front shortcut")
	quit()
