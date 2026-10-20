extends SceneTree
func _initialize() -> void: call_deferred("run")
func press(garage: Control,index: int,point: Vector2) -> void:
	var event := InputEventScreenTouch.new(); event.index = index; event.position = point; event.pressed = true
	garage._on_preview_input(event)
func drag(garage: Control,index: int,point: Vector2,relative: Vector2) -> void:
	var event := InputEventScreenDrag.new(); event.index = index
	event.position = garage._preview.get_global_transform_with_canvas()*point; event.relative = relative; garage._input(event)
func run() -> void:
	root.size = Vector2i(1280,720)
	var world: Node3D = load("res://scenes/test_environment.tscn").instantiate(); root.add_child(world)
	var car: CharacterBody3D = world.get_node("VehicleSpawn/PlayerCar")
	var pause_menu := car.get_node("PauseMenu"); pause_menu.open_menu(); pause_menu._open_garage()
	for i in range(4): await process_frame
	var garage: Control = pause_menu.get_node("Garage")
	var start: Vector2 = garage._preview.size*0.4
	var original_car := car.global_transform; var angle: float = garage._model.rotation.y
	press(garage,0,start); drag(garage,0,start+Vector2(60,0),Vector2(60,0))
	assert(absf(garage._model.rotation.y-angle)>0.1,"One finger rotates garage preview")
	var distance: float = garage._orbit_distance
	press(garage,1,start+Vector2(160,0)); drag(garage,1,start+Vector2(210,0),Vector2(50,0))
	assert(garage._orbit_distance<distance and garage._orbit_distance>=5.2,"Pinch out zooms toward car within bounds")
	assert(car.global_transform==original_car,"Garage gestures do not move the actual driving vehicle")
	for index in [0,1]:
		var release := InputEventScreenTouch.new(); release.index = index; release.pressed = false; garage._input(release)
	assert(garage._touch_points.is_empty(),"Touch release clears finger ownership")
	press(garage,2,start); garage.hide()
	assert(garage._touch_points.is_empty(),"Closing garage clears touch gestures")
	garage.show(); press(garage,3,start); garage._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(garage._touch_points.is_empty(),"Focus loss clears touch gestures")
	pause_menu.close_menu(); world.queue_free(); await process_frame
	print("GARAGE TOUCH PASS: rotation, pinch zoom, bounds, isolated car transform and cleanup")
	quit()
