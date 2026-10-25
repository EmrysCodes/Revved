extends SceneTree
const PILOT = preload("res://racing/route_pilot.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.get_node("StreetProfile").launch_mode="free"
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate()
	city.set_meta("disable_population",true);root.add_child(city)
	for i in range(12):await physics_frame
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://racing/capital_run_route.json"))
	var path:=PackedVector3Array();var distances:=PackedFloat64Array([0.0])
	for point: Array in data.points.slice(0,439):path.append(Vector3(point[0],point[1],point[2]))
	for i in range(1,path.size()):distances.append(distances[-1]+path[i-1].distance_to(path[i]))
	var car: CharacterBody3D=city.car;car.set_physics_process(false)
	car.global_position=path[0]+Vector3.UP*0.2
	car.rotation.y=atan2(-(path[1].x-path[0].x),-(path[1].z-path[0].z));car.velocity=Vector3.ZERO
	for i in range(30):car._step_motion(1.0/60,0,0,true,false);await physics_frame
	var cursor:=0;var air:=0;var finished:=false
	for frame in range(9000):
		var input: Dictionary=PILOT.command(car,path,distances,cursor,28,0)
		cursor=input.cursor;car._step_motion(1.0/60,input.throttle,input.steering,input.brake,false)
		await physics_frame
		if not car.is_on_floor():air+=1
		if cursor>=path.size()-7:finished=true;break
	if not finished or air>=60:
		push_error("Downtown drive failed cursor=%d air=%d"%[cursor,air]);city.queue_free();await process_frame;quit(1);return
	print("DOWNTOWN DRIVE PASS cursor=",cursor,"/",path.size()," air_frames=",air)
	city.queue_free();await process_frame;quit()
