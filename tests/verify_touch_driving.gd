extends SceneTree
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value: push_error(message);quit(1);assert(value,message)
func touch(controls: Control,id: int,key: String,down: bool) -> void:
	var event:=InputEventScreenTouch.new();event.index=id;event.position=controls.buttons[key].get_center();event.pressed=down
	controls.call("_input",event)
func run() -> void:
	root.get_node("StreetProfile").touch_mode=1
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate();root.add_child(city)
	for i in range(12): await physics_frame
	var car: CharacterBody3D=city.car
	var controls: Control=car.get_node("HUD/Screen/TouchControls")
	check(controls.enabled and controls.visible,"Touch controls enabled")
	touch(controls,0,"gas",true);touch(controls,1,"left",true)
	check(controls.held("gas") and controls.held("left"),"Independent simultaneous gas and steering")
	for i in range(75): await physics_frame
	check(car.velocity.length()>2 and car.get("_steering")< -0.5,"Touch input drives real throttle and steering")
	touch(controls,2,"ebrake",true)
	for i in range(10): await physics_frame
	check(car.get("_handbraking"),"Third touch applies handbrake")
	touch(controls,0,"gas",false)
	check(not controls.held("gas") and controls.held("left") and controls.held("ebrake"),"Releasing one finger preserves other inputs")
	controls.release_all();car.velocity=-car.global_basis.z*15
	touch(controls,4,"brake",true)
	for i in range(40): await physics_frame
	check(car.velocity.length()<12,"Touch brake slows the vehicle")
	var drag:=InputEventScreenDrag.new();drag.index=4;drag.position=Vector2(640,300);controls.call("_input",drag)
	check(not controls.held("brake"),"Dragging off releases input")
	touch(controls,0,"gas",true);car.get_node("PauseMenu").open_menu()
	for i in range(3): await process_frame
	check(not controls.held("gas") and not controls.visible,"Pause clears touch input and hides driving buttons")
	car.get_node("PauseMenu").close_menu()
	for i in range(3): await process_frame
	touch(controls,0,"gas",true);controls.call("_notification",Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not controls.held("gas"),"Focus loss clears inputs")
	car.controls_locked=true;touch(controls,0,"gas",true)
	check(not controls.held("gas"),"Countdown lock blocks touch throttle")
	car.controls_locked=false
	for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1080),Vector2i(393,852)]:
		root.size=resolution
		for i in range(3): await process_frame
		for key in controls.buttons: check(Rect2(Vector2.ZERO,controls.size).encloses(controls.buttons[key]),"Touch target fits viewport "+key+str(resolution))
	print("PASS: multitouch gas/steering/handbrake, brake, release/drag, pause/focus cleanup, lock and layouts")
	quit()
