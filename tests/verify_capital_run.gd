extends SceneTree
const STEP:=1.0/60.0
var event: Node
var city: Node3D
var car: CharacterBody3D
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool,message: String) -> void:
	if not value:
		push_error(message);quit(1);assert(value,message)
func cross_gate(driver: CharacterBody3D,gate: int,reverse:=false,height:=0.1) -> void:
	var index: int=event.checkpoint_indices[gate]
	var point: Vector3=event.route[index]+Vector3.UP*height
	var normal: Vector3=event.route[mini(index+3,event.route.size()-1)]-event.route[maxi(0,index-3)]
	normal.y=0;normal=normal.normalized()
	if reverse: normal=-normal
	driver.global_position=point-normal
	event.sync_previous(driver)
	driver.global_position=point+normal
	event.call("_check_driver",driver,STEP)
func _run() -> void:
	city=load("res://scenes/hartford_district.tscn").instantiate();root.add_child(city)
	for i in range(12): await physics_frame
	car=city.car;car.set_physics_process(false)
	event=city.get_node("CityRace")
	event.best_path="res://tests/capital-run.tmp";event.best_time=INF
	check(event.route.size()>500 and event.checkpoint_indices.size()>20,"Substantial curated course")
	check(event.state==event.Phase.FREE_ROAM and event.hud.card.visible,"Free-roam event entry")
	var original:=car.global_transform
	event.start_race()
	check(event.opponents.size()==3 and car.controls_locked,"Three rivals and countdown lock")
	check(city.get_node("CityHUD/Screen/Map").is_visible_in_tree() and not city.readout.visible,"Race map remains visible without free-roam text")
	for rival in event.opponents: rival.set_physics_process(false)
	check(root.get_camera_3d()==car.get_node("CameraArm/FollowCamera"),"Rivals do not steal the camera")
	var staged:=car.position
	for i in range(90): await physics_frame
	check(event.state==event.Phase.COUNTDOWN and event.elapsed==0 and car.position.is_equal_approx(staged),"Countdown starts before race clock or motion")
	for i in range(100): await physics_frame
	check(event.is_running() and not car.controls_locked,"Green light unlocks player")
	var menu: CanvasLayer=car.get_node("PauseMenu")
	menu.open_menu()
	var paused_time: float=event.elapsed
	for i in range(8): await process_frame
	check(is_equal_approx(event.elapsed,paused_time),"Pause freezes race timer")
	menu.close_menu()
	event.set_physics_process(false)
	var id:=car.get_instance_id()
	cross_gate(car,1)
	check(event.next_checkpoint[id]==0,"Cannot skip gates")
	cross_gate(car,0,true)
	check(event.next_checkpoint[id]==0,"Wrong-way crossing rejected")
	cross_gate(car,0,false,5)
	check(event.next_checkpoint[id]==0,"Wrong elevation rejected")
	cross_gate(car,0)
	check(event.next_checkpoint[id]==1,"Ordered forward sweep advances gate")
	cross_gate(car,0)
	check(event.next_checkpoint[id]==1,"Repeated gate cannot advance race")
	event.elapsed=7
	car.call("_reset_car")
	check(event.next_checkpoint[id]==1 and car.controls_locked and event.player_recoveries==1,"Reset recovers behind last checkpoint without progress loss")
	event.call("_physics_process",1.0);event.call("_physics_process",1.0)
	check(not car.controls_locked and event.elapsed>=9,"Recovery wait costs real race time")
	var winner: CharacterBody3D=event.opponents[0]
	for gate in range(event.checkpoint_indices.size()):
		event.elapsed+=1;cross_gate(winner,gate)
	check(winner.finished and event.finish_times.has(winner.get_instance_id()),"AI can finish before player")
	for gate in range(1,event.checkpoint_indices.size()):
		event.elapsed+=1;cross_gate(car,gate)
	check(event.state==event.Phase.RESULTS and car.controls_locked,"Finish opens results and locks driving")
	check(event.player_place()==2 and event.hud.results_overlay.visible,"Correct finish ranking")
	check(event.best_time>0 and event.best_saved,"Personal best is persisted")
	var late_rival: CharacterBody3D=event.opponents[1]
	check(event.rivals_can_drive(),"Unfinished rivals keep racing during results")
	for gate in range(event.checkpoint_indices.size()):
		event.elapsed+=1;cross_gate(late_rival,gate)
	check(late_rival.finished and event.finish_times.has(late_rival.get_instance_id()),"Late rival finishes and refreshes results")
	check(event.player_place()==2,"Late finish does not change player's finishing place")
	var saved:=ConfigFile.new();check(saved.load(event.best_path)==OK,"Best-time file exists")
	check(is_equal_approx(saved.get_value(event.best_key(),"best_seconds"),event.best_time),"Saved best matches result")
	for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1080)]:
		root.size=resolution
		for i in range(4): await process_frame
		check(root.get_visible_rect().encloses(event.hud.results_card.get_global_rect()),"Results fit viewport "+str(resolution))
	event.hud.retry.pressed.emit()
	for i in range(3): await physics_frame
	check(event.state==event.Phase.COUNTDOWN and event.elapsed==0 and event.opponents.size()==3,"Results retry resets event and rivals")
	menu.open_menu();menu.get_node("Overlay/Center/Card/Padding/Stack/LeaveCityRace").pressed.emit()
	check(not paused and event.state==event.Phase.FREE_ROAM and event.opponents.is_empty(),"Pause menu can return to free roam")
	check(not car.controls_locked and car.collision_mask==5 and city.get_node("CityHUD").visible,"Free-roam controls/collision/HUD restored")
	check(car.global_transform.is_equal_approx(original),"Return to pre-race location")
	DirAccess.remove_absolute(event.best_path)
	print("PASS: race entry, countdown, camera, pause, ordered/directional/height gates, recovery, AI/player results, ranking, best persistence, retry, layouts and free-roam restoration")
	quit()
