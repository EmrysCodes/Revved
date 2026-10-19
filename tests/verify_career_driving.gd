extends SceneTree
const C=preload("res://core/career_catalog.gd")
const PILOT=preload("res://racing/route_pilot.gd")
const STEP:=1.0/60.0
var failures:Array[String]=[]
func _initialize() -> void:
	Engine.time_scale=1;Engine.max_fps=0
	call_deferred("run")
func run() -> void:
	var profile=root.get_node("StreetProfile")
	profile.launch_mode="single";profile.selected_event="capital_run"
	var city:Node3D=load("res://scenes/hartford_district.tscn").instantiate()
	city.set_meta("offline_build",true);root.add_child(city)
	city.add_child(load("res://world/eastside/frontage.tscn").instantiate())
	var initial:Node=load("res://racing/capital_run.tscn").instantiate();initial.name="CityRace";city.add_child(initial)
	for i in range(14):await physics_frame
	var car:CharacterBody3D=city.car;car.set_physics_process(false)
	for definition:Dictionary in C.EVENTS:
		if not OS.get_cmdline_user_args().is_empty():
			var filter:String=OS.get_cmdline_user_args()[0]
			if filter=="eastside" and definition.chapter!=1:continue
			if filter!="eastside" and definition.id!=filter:continue
		var old=city.get_node("CityRace");old.exit_to_free_roam();city.remove_child(old);old.free()
		profile.selected_event=definition.id
		var event:Node=load("res://racing/capital_run.tscn").instantiate();event.name="CityRace";city.add_child(event)
		event.best_path="res://tests/career-driving.tmp";event.start_race();event.set_physics_process(false)
		for rival in event.opponents:rival.set_physics_process(false);rival.collision_layer=0;rival.hide()
		var cursor:=0;var air:=0;var finished:=false;var stalled:=0;var previous_gate:=-1
		for frame in range(int(event.length/9*60)+4000):
			if event.is_running() and not car.controls_locked:
				var inputs:Dictionary=PILOT.command(car,event.route,event.distances,cursor,30,0)
				cursor=inputs.cursor
				car.call("_step_motion",STEP,inputs.throttle,inputs.steering,inputs.brake,false)
				if not car.is_on_floor():air+=1
			else:car.call("_step_motion",STEP,0,0,true,false)
			event.call("_physics_process",STEP)
			if frame%8==0:await physics_frame
			var gate:int=event.next_checkpoint.get(car.get_instance_id(),0)
			if gate!=previous_gate:previous_gate=gate;stalled=0
			else:stalled+=1
			if event.state==event.Phase.RESULTS:finished=true;break
			if frame%600==0:print("CHECK ",definition.id," frame=",frame," gate=",gate," cursor=",cursor)
			if stalled>4200:
				for i in range(car.get_slide_collision_count()):print("BLOCKER ",car.get_slide_collision(i).get_collider().get_path())
				break
		print("DRIVE ",definition.id," finished=",finished," gate=",previous_gate,"/",event.checkpoint_indices.size()," time=",snappedf(event.elapsed,.1)," air=",air," pos=",car.position," cursor=",cursor)
		if not finished or air>240:failures.append(definition.id)
		event.exit_to_free_roam()
	DirAccess.remove_absolute("res://tests/career-driving.tmp")
	print("CAREER DRIVING ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	quit(0 if failures.is_empty() else 1)
