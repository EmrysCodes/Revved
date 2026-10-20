extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failed = true; push_error(message)
func run() -> void:
	var settings := root.get_node("GameSettings")
	var profile := root.get_node("StreetProfile")
	var saved_vehicle: int = settings.vehicle_id
	var saved_cash: int = profile.credits
	var saved_tiers: Array = profile.purchased_tiers.duplicate()
	var city: Node3D = load("res://scenes/night_showcase.tscn").instantiate()
	root.add_child(city)
	while not city.ready_to_drive: await physics_frame
	for i in range(25): await physics_frame
	check(settings.vehicle_id == saved_vehicle and profile.credits == saved_cash and profile.purchased_tiers == saved_tiers,"Showcase does not modify career or garage state")
	var car: CharacterBody3D = city.car
	car.set_physics_process(false)
	check(car.get_node("Visuals/S64Compact")._active_vehicle==5, "Clean benchmark car selected locally")
	check(car.has_node("NightHeadlights"),"Working headlight rig installed")
	check(city.get_node("ModernCityStreet/Collision").get_child_count()>=30,"Road, curb and building collision installed")
	var visuals := city.get_node("ModernCityStreet/Architecture").find_children("*","MeshInstance3D",true,false)
	check(visuals.size()==34,"Imported street has one set of geometry chunks")
	var legacy_alpha := 0; var mapped := 0
	for visual: MeshInstance3D in visuals:
		for index in range(visual.mesh.get_surface_count()):
			var mat: Material = visual.mesh.surface_get_material(index)
			if mat is BaseMaterial3D:
				if mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS: legacy_alpha += 1
				if mat.normal_enabled and mat.normal_texture: mapped += 1
	check(legacy_alpha==0 and mapped>50,"Saved scene retains PBR maps and corrected imported transparency")
	var space := city.get_world_3d().direct_space_state
	for x in [-70,-50,-20,10,40,70]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,3,-1.55),Vector3(x,-2,-1.55),1,[car.get_rid()]))
		check(not hit.is_empty() and absf(hit.position.y)<0.3,"Drive lane has continuous ground at "+str(x))
	var wall_hits := 0
	for x in [-70,-40,10,40,70]:
		for side in [-1,1]:
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,1,0),Vector3(x,1,side*18),1,[car.get_rid()]))
			if not hit.is_empty(): wall_hits += 1
	check(wall_hits>=4,"Building frontages stop the car at street level")
	var start := car.position
	var air_frames := 0
	for i in range(1500):
		car._step_motion(1.0/60,0.40,0.0,false,false)
		await physics_frame
		if i>10 and not car.is_on_floor(): air_frames += 1
		if car.position.x-start.x > 140: break
	print("SHOWCASE DRIVE distance=",car.position.x-start.x," air=",air_frames," end=",car.position)
	check(car.position.x-start.x>140 and air_frames<=3,"Player drives 140 metres through actual street collision")
	car._reset_car(); await physics_frame
	check(car.position.distance_to(start)<1.0,"Reset returns to the lit street spawn")
	car.position = Vector3(-70,0.03,-1.55); car.rotation.y = 0
	var highest := 0.0
	for i in range(240):
		car._step_motion(1.0/60,0.25,0.0,false,false)
		await physics_frame
		highest = maxf(highest,car.position.y)
		if car.position.z < -3.5: break
	print("SHOWCASE CURB position=",car.position," highest=",highest)
	# The narrow pavement ends at a shopfront: the nose should climb the curb
	# and then stop at the wall, rather than pass through the building.
	check(highest>0.1 and car.position.z < -3.0,"Car climbs the physical curb before the solid shopfront")
	car._reset_car(); await physics_frame
	city.simple_lighting = true; city.light_timer = 1.0; city._process(0.01)
	var active := 0
	for lamp in city.lights:
		if lamp.visible: active += 1
	check(active<=8,"Reduced lighting caps active local lights")
	city.toggle_photo()
	check(city.photo_camera.current and car.controls_locked and not car.get_node("HUD").visible,"Car-view camera disables driving and hides driving HUD")
	city.toggle_photo()
	check(car.get_node("CameraArm/FollowCamera").current and not car.controls_locked and car.get_node("HUD").visible,"Return to drive restores camera, input and HUD")
	city.queue_free()
	for i in range(5): await process_frame
	check(settings.vehicle_id==saved_vehicle and profile.credits==saved_cash,"Leaving showcase preserves saved player choices")
	print("NIGHT SHOWCASE ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
