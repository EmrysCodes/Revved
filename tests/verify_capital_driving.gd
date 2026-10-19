extends SceneTree
const PILOT:=preload("res://racing/route_pilot.gd")
const STEP:=1.0/60.0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate();root.add_child(city)
	for i in range(12): await physics_frame
	var car: CharacterBody3D=city.car;car.set_physics_process(false)
	var event: Node=city.get_node("CityRace")
	event.best_path="res://tests/capital-driving.tmp"
	event.start_race()
	var cursor:=0
	var air:=0
	var last_checkpoint:=-1
	for frame in range(42000):
		if event.is_running() and not car.controls_locked:
			var inputs: Dictionary=PILOT.command(car,event.route,event.distances,cursor,36.0,0.0)
			cursor=inputs.cursor
			car.call("_step_motion",STEP,inputs.throttle,inputs.steering,inputs.brake,false)
			if not car.is_on_floor(): air+=1
		else:
			car.call("_step_motion",STEP,0.0,0.0,true,false)
		await physics_frame
		var checkpoint: int=event.next_checkpoint.get(car.get_instance_id(),0)
		if checkpoint!=last_checkpoint:
			print("PLAYER CP ",checkpoint,"/",event.checkpoint_indices.size()," time ",event.elapsed," position ",car.position)
			last_checkpoint=checkpoint
		if frame%3600==0:
			for rival in event.opponents:
				print("RIVAL ",rival.rival_name," CP ",event.next_checkpoint[rival.get_instance_id()]," cursor ",rival.cursor," recoveries ",rival.recoveries," position ",rival.position)
		if event.state==event.Phase.RESULTS: break
	if event.state!=event.Phase.RESULTS:
		push_error("Player must physically drive the full sprint");quit(1);return
	if air>180:
		push_error("Race route must not involve extended falling");quit(1);return
	var finished_rivals:=0
	for rival in event.opponents:
		print("FINAL RIVAL ",rival.rival_name," CP ",event.next_checkpoint[rival.get_instance_id()]," recoveries ",rival.recoveries)
		if event.finish_times.has(rival.get_instance_id()): finished_rivals+=1
	if finished_rivals<2:
		push_error("At least two faster rivals must complete their full course");quit(1);return
	print("PASS: real four-car city sprint, all player checkpoints, ",finished_rivals," rival finishes, time ",event.elapsed," air frames ",air)
	event.exit_to_free_roam()
	DirAccess.remove_absolute(event.best_path)
	quit()
